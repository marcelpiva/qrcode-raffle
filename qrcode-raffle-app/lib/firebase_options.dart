// File generated manually based on google-services.json and GoogleService-Info.plist
// Equivalent to what flutterfire configure would generate

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
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDX3oMXhx_LGyluKR6JbK8NOVuHXoOY5is',
    appId: '1:1055457110514:android:0eba1fcbf10428e9aa636b',
    messagingSenderId: '1055457110514',
    projectId: 'raffle-b89bc',
    storageBucket: 'raffle-b89bc.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCt9O7mp3olyLNtBG1x3w-jZfyuhAjl8o8',
    appId: '1:1055457110514:ios:5513cc4c8b027626aa636b',
    messagingSenderId: '1055457110514',
    projectId: 'raffle-b89bc',
    storageBucket: 'raffle-b89bc.firebasestorage.app',
    iosBundleId: 'com.qrcoderaffle.qrcodeRaffleApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCt9O7mp3olyLNtBG1x3w-jZfyuhAjl8o8',
    appId: '1:1055457110514:ios:5513cc4c8b027626aa636b',
    messagingSenderId: '1055457110514',
    projectId: 'raffle-b89bc',
    storageBucket: 'raffle-b89bc.firebasestorage.app',
    iosBundleId: 'com.qrcoderaffle.qrcodeRaffleApp',
  );
}
