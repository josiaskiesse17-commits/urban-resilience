import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../auth/domain/app_user.dart';

class FcmService {
  FcmService({
    required this._messaging,
    required this._firestore,
    required this._auth,
  });

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  AppUser? _currentUser;
  String? _currentToken;
  StreamSubscription<User?>? _authStateSubscription;
  StreamSubscription<RemoteMessage>? _onMessageSubscription;
  StreamSubscription<RemoteMessage>? _onMessageOpenedAppSubscription;
  StreamSubscription<String?>? _onTokenRefreshSubscription;

  Future<void> initialize() async {
    try {
      // Request permission for iOS
      if (Platform.isIOS) {
        await _messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      // Listen to auth state changes
      _authStateSubscription = _auth.authStateChanges().listen(_onAuthStateChanged);

      // Get initial token if we already have a user
      if (_currentUser != null) {
        await _refreshToken(null);
      }

      // Handle token refresh
      _onTokenRefreshSubscription =
          FirebaseMessaging.instance.onTokenRefresh.listen(_refreshToken);

      // Handle foreground messages
      _onMessageSubscription =
          FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification tap when app is opened from background or terminated
      _onMessageOpenedAppSubscription =
          FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Handle initial notification when app is launched from terminated state
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }
    } catch (e, stackTrace) {
      // FCM initialization failed, but we don't want to crash the app
      debugPrint('FCM initialization failed: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _onAuthStateChanged(User? user) async {
    AppUser? appUser;
    if (user == null) {
      appUser = null;
    } else {
      appUser = AppUser(
        id: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
        emailVerified: user.emailVerified,
      );
    }

    // If there was a previous user and we have a token, delete the token document for that user
    if (_currentUser != null && _currentToken != null) {
      try {
        await _firestore
            .collection('users')
            .doc(_currentUser!.id)
            .collection('fcm_tokens')
            .doc(_currentToken)
            .delete();
      } catch (e) {
        // Ignore delete errors (e.g., if document doesn't exist)
        debugPrint('Failed to delete FCM token for outgoing user: $e');
      }
    }

    _currentUser = appUser;

    // If there is a new user, refresh the token to associate it with the user
    if (_currentUser != null) {
      await _refreshToken(null);
    }
  }

  Future<void> _refreshToken(String? token) async {
    if (_currentUser == null) {
      // No user signed in, do not save token
      return;
    }

    String? fcmToken = token;
    if (fcmToken == null) {
      try {
        fcmToken = await _messaging.getToken();
      } catch (e) {
        debugPrint('Failed to get FCM token: $e');
        return;
      }
    }

    if (fcmToken == null) {
      return;
    }

    try {
      final platform = Platform.isAndroid
          ? 'android'
          : Platform.isIOS
              ? 'ios'
              : 'web';

      // Delete previous token document if we have one
      if (_currentToken != null) {
        try {
          await _firestore
              .collection('users')
              .doc(_currentUser!.id)
              .collection('fcm_tokens')
              .doc(_currentToken)
              .delete();
        } catch (e) {
          // Ignore delete errors (e.g., if document doesn't exist)
          debugPrint('Failed to delete old FCM token: $e');
        }
      }

      _currentToken = fcmToken;

      await _firestore
          .collection('users')
          .doc(_currentUser!.id)
          .collection('fcm_tokens')
          .doc(fcmToken)
          .set({
        'token': fcmToken,
        'platform': platform,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e, stackTrace) {
      debugPrint('Failed to save FCM token: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    // Log the message for debugging
    debugPrint('FCM foreground message: $message');
    // Do not modify app state or trigger navigation
  }

  void _handleNotificationTap(RemoteMessage message) {
    // Log the message for debugging
    debugPrint('FCM notification tapped: $message');
    // Do not navigate yet; will be handled in later phases
  }

  Future<void> dispose() async {
    await _authStateSubscription?.cancel();
    await _onMessageSubscription?.cancel();
    await _onMessageOpenedAppSubscription?.cancel();
    await _onTokenRefreshSubscription?.cancel();
  }
}

// Top-level background message handler required by Firebase Messaging
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if not already done (though it should be)
  if (Firebase.apps.isNotEmpty) {
    // Already initialized
  } else {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      // Ignore initialization errors in background
      return;
    }
  }

  // Log the message (no UI access, no navigation)
  debugPrint('FCM background message: $message');
}