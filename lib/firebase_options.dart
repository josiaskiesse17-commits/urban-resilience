

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;











class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAHypoVd-7T-5gRMbLpvQthk5gpZwnKzEw',
    appId: '1:1013612055908:web:844f8d26716056f5f27e71',
    messagingSenderId: '1013612055908',
    projectId: 'urban-resilience-f875d',
    authDomain: 'urban-resilience-f875d.firebaseapp.com',
    storageBucket: 'urban-resilience-f875d.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDhht2LHUKSsdGt05bOS8XgeuViCyDgJ9A',
    appId: '1:1013612055908:android:25b166287ff02be7f27e71',
    messagingSenderId: '1013612055908',
    projectId: 'urban-resilience-f875d',
    storageBucket: 'urban-resilience-f875d.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBPjSnkf-b_f-2J6drdKVjWdQm1phlumoU',
    appId: '1:1013612055908:ios:1edea227d500f717f27e71',
    messagingSenderId: '1013612055908',
    projectId: 'urban-resilience-f875d',
    storageBucket: 'urban-resilience-f875d.firebasestorage.app',
    iosBundleId: 'com.namegmail.urbanResilience',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBPjSnkf-b_f-2J6drdKVjWdQm1phlumoU',
    appId: '1:1013612055908:ios:1edea227d500f717f27e71',
    messagingSenderId: '1013612055908',
    projectId: 'urban-resilience-f875d',
    storageBucket: 'urban-resilience-f875d.firebasestorage.app',
    iosBundleId: 'com.namegmail.urbanResilience',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAHypoVd-7T-5gRMbLpvQthk5gpZwnKzEw',
    appId: '1:1013612055908:web:2985ac7ae411e3c1f27e71',
    messagingSenderId: '1013612055908',
    projectId: 'urban-resilience-f875d',
    authDomain: 'urban-resilience-f875d.firebaseapp.com',
    storageBucket: 'urban-resilience-f875d.firebasestorage.app',
  );
}
