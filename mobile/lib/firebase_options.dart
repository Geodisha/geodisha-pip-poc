// 
// ⚠️ FIREBASE IS DISABLED ⚠️
// This app doesn't use Firebase - all code commented out
//
/*
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // ... all the platform detection code
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDemoKey123456789',
    appId: '1:123456789:web:abc123',
    messagingSenderId: '123456789',
    projectId: 'geodisha-demo',
    authDomain: 'geodisha-demo.firebaseapp.com',
    storageBucket: 'geodisha-demo.appspot.com',
    measurementId: 'G-MEASUREMENT',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDemoKey123456789',
    appId: '1:123456789:android:abc123',
    messagingSenderId: '123456789',
    projectId: 'geodisha-demo',
    storageBucket: 'geodisha-demo.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDemoKey123456789',
    appId: '1:123456789:ios:abc123',
    messagingSenderId: '123456789',
    projectId: 'geodisha-demo',
    storageBucket: 'geodisha-demo.appspot.com',
    iosClientId: '123456789.apps.googleusercontent.com',
    iosBundleId: 'com.geodisha.mobile',
  );
}
*/

// Dummy class to prevent compilation errors
class DefaultFirebaseOptions {
  static dynamic get currentPlatform => null;
}
