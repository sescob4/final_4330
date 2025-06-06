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
    apiKey: 'AIzaSyCxSppJMqe-tLdHm8PymwsDBK0OmxYEO30',
    appId: '1:113598733750:web:dc6ae1d4636d4fbbc13517',
    messagingSenderId: '113598733750',
    projectId: 'project-d7d3a',
    authDomain: 'project-d7d3a.firebaseapp.com',
    storageBucket: 'project-d7d3a.firebasestorage.app',
    databaseURL: 'https://project-d7d3a-default-rtdb.firebaseio.com/'

  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBBs3qs4pvbcREnwhrczApz23Y3KmEaaTQ',
    appId: '1:113598733750:android:964b248d67cd700cc13517',
    messagingSenderId: '113598733750',
    projectId: 'project-d7d3a',
    storageBucket: 'project-d7d3a.firebasestorage.app',
    databaseURL: 'https://project-d7d3a-default-rtdb.firebaseio.com/'

  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCLJYy4W1isCd5oT2R3s1MlwUMB3ZSxOAY',
    appId: '1:113598733750:ios:0464c78c5d5a2752c13517',
    messagingSenderId: '113598733750',
    projectId: 'project-d7d3a',
    storageBucket: 'project-d7d3a.firebasestorage.app',
    iosBundleId: 'com.example.final4330',
    databaseURL: 'https://project-d7d3a-default-rtdb.firebaseio.com/',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCLJYy4W1isCd5oT2R3s1MlwUMB3ZSxOAY',
    appId: '1:113598733750:ios:0464c78c5d5a2752c13517',
    messagingSenderId: '113598733750',
    projectId: 'project-d7d3a',
    storageBucket: 'project-d7d3a.firebasestorage.app',
    iosBundleId: 'com.example.final4330',
    databaseURL: 'https://project-d7d3a-default-rtdb.firebaseio.com/',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCxSppJMqe-tLdHm8PymwsDBK0OmxYEO30',
    appId: '1:113598733750:web:1d4545840cb7d70cc13517',
    messagingSenderId: '113598733750',
    projectId: 'project-d7d3a',
    authDomain: 'project-d7d3a.firebaseapp.com',
    storageBucket: 'project-d7d3a.firebasestorage.app',
    databaseURL: 'https://project-d7d3a-default-rtdb.firebaseio.com/',
  );

}
