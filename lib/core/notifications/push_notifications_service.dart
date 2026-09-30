import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

import '../../firebase_options.dart';
import '../router/app_router.dart';

/// Client side of the "notify admins of a new observation" feature.
///
/// The server side lives in `functions/index.js`
/// (`notifyAdminsOnNewObservation`): whenever a citizen submits an
/// observation, that Cloud Function pushes a notification to every FCM
/// token stored in `users/{adminUid}.fcmTokens`, using Firebase Cloud
/// Messaging. FCM delivers it through the OS (Google/Apple push services),
/// so it arrives even if the app is closed or the phone is asleep — this
/// class only needs to keep that token array in sync and react to taps.
class PushNotificationsService {
  const PushNotificationsService._();

  static const _androidChannel = AndroidNotificationChannel(
    'observations',
    'Nouveaux signalements',
    description:
        'Notifications envoyées aux administrateurs pour chaque nouveau '
        'signalement citoyen.',
    importance: Importance.high,
  );

  static final _localNotifications = FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static StreamSubscription<String>? _tokenRefreshSubscription;

  static bool get _supportsFcm =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Registers the background message handler. Must be called once in
  /// `main()`, before `runApp`, so notifications can still be received
  /// while the app is fully closed (not just backgrounded).
  static void registerBackgroundHandler() {
    if (!_supportsFcm) return;
    FirebaseMessaging.onBackgroundMessage(_backgroundMessageHandler);
  }

  /// Call whenever a user finishes signing in (including an app cold
  /// start where they were already signed in). Requests notification
  /// permission and, if granted, saves this device's FCM token to the
  /// user's Firestore document so the Cloud Function can reach it.
  ///
  /// Safe to call for any signed-in user, not just admins: citizens
  /// simply won't have a matching document read by the Cloud Function's
  /// `role == 'admin'` query, so storing their token is harmless.
  static Future<void> registerForCurrentUser(String userId) async {
    if (!_supportsFcm) return;

    await _ensureInitialized();

    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final granted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
    if (!granted) return;

    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await _saveToken(userId, token);
    }

    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh
        .listen((newToken) => _saveToken(userId, newToken));
  }

  /// Call before signing the current user out, so this device stops
  /// receiving notifications for an account it is no longer signed into.
  /// Must run while still authenticated: Firestore rules only allow a
  /// user to edit their own `fcmTokens`.
  static Future<void> clearTokenForCurrentUser() async {
    if (!_supportsFcm) return;

    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await FirebaseFirestore.instance.collection('users').doc(userId).set(
        {
          'fcmTokens': FieldValue.arrayRemove([token]),
        },
        SetOptions(merge: true),
      );
    } catch (_) {
      // Best-effort only. If this fails (e.g. offline sign-out), the
      // Cloud Function already prunes tokens FCM reports as invalid.
    }
  }

  static Future<void> _ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      ),
      onDidReceiveNotificationResponse: (response) {
        final observationId = response.payload;
        if (observationId != null && observationId.isNotEmpty) {
          _openObservation(observationId);
        }
      },
    );

    if (defaultTargetPlatform == TargetPlatform.android) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_androidChannel);
    }

    // FCM does not display a system notification while the app is in the
    // foreground: show one ourselves so admins notice a new report even
    // if they currently have the app open on another screen.
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;

      _localNotifications.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: message.data['observationId'] as String?,
      );
    });

    // Notification tapped while the app was backgrounded.
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final observationId = message.data['observationId'] as String?;
      if (observationId != null) _openObservation(observationId);
    });

    // App launched from a fully closed state by tapping a notification.
    final initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    final initialObservationId =
        initialMessage?.data['observationId'] as String?;
    if (initialObservationId != null) {
      _openObservation(initialObservationId);
    }
  }

  static void _openObservation(String observationId) {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;
    GoRouter.of(context).push('/observations/detail/$observationId');
  }

  static Future<void> _saveToken(String userId, String token) {
    return FirebaseFirestore.instance.collection('users').doc(userId).set(
      {
        'fcmTokens': FieldValue.arrayUnion([token]),
      },
      SetOptions(merge: true),
    );
  }
}

/// Top-level function required by [FirebaseMessaging.onBackgroundMessage].
/// Runs in its own isolate with no access to the rest of the app, so it
/// only needs to make sure Firebase is initialised; the OS displays the
/// notification automatically from the message's `notification` payload.
@pragma('vm:entry-point')
Future<void> _backgroundMessageHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}
