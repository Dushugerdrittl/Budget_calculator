// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
    apiKey: 'AIzaSyB0eNo4wG056UbWsFCWYg9SJZGqcn7uYbI',
    appId: '1:494307442432:web:f61aaaa0627c5252833de5',
    messagingSenderId: '494307442432',
    projectId: 'expbase-1e44a',
    authDomain: 'expbase-1e44a.firebaseapp.com',
    databaseURL: 'https://expbase-1e44a-default-rtdb.firebaseio.com',
    storageBucket: 'expbase-1e44a.firebasestorage.app',
    measurementId: 'G-FW31HKMLK7',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCGPkZLqO0qGOg0VEF7-FMOEUoqMpBLBOU',
    appId: '1:494307442432:android:66c9a8de7d029e8e833de5',
    messagingSenderId: '494307442432',
    projectId: 'expbase-1e44a',
    databaseURL: 'https://expbase-1e44a-default-rtdb.firebaseio.com',
    storageBucket: 'expbase-1e44a.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAbwtzKKj9B4eqzJDag7N-VdJrqFyBGRQs',
    appId: '1:494307442432:ios:5a000f4983540aa3833de5',
    messagingSenderId: '494307442432',
    projectId: 'expbase-1e44a',
    databaseURL: 'https://expbase-1e44a-default-rtdb.firebaseio.com',
    storageBucket: 'expbase-1e44a.firebasestorage.app',
    iosBundleId: 'com.fxkittyexpense.appkit',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAbwtzKKj9B4eqzJDag7N-VdJrqFyBGRQs',
    appId: '1:494307442432:ios:5ddba54aa539add7833de5',
    messagingSenderId: '494307442432',
    projectId: 'expbase-1e44a',
    databaseURL: 'https://expbase-1e44a-default-rtdb.firebaseio.com',
    storageBucket: 'expbase-1e44a.firebasestorage.app',
    iosBundleId: 'com.example.expance',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyB0eNo4wG056UbWsFCWYg9SJZGqcn7uYbI',
    appId: '1:494307442432:web:c0a757061e47b8d2833de5',
    messagingSenderId: '494307442432',
    projectId: 'expbase-1e44a',
    authDomain: 'expbase-1e44a.firebaseapp.com',
    databaseURL: 'https://expbase-1e44a-default-rtdb.firebaseio.com',
    storageBucket: 'expbase-1e44a.firebasestorage.app',
    measurementId: 'G-W07MNLF6QR',
  );
}
