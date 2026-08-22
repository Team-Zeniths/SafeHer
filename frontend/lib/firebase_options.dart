// File generated manually from android/app/google-services.json.
// If you ever add iOS/web/macOS targets, regenerate this properly with:
//   dart pub global activate flutterfire_cli
//   flutterfire configure
//
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'run `flutterfire configure` if you add a web target.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for '
          '$defaultTargetPlatform - run `flutterfire configure` to add it.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA8IhbmGWwSmG7kUm-Qz0Aqlgrs1ZD57uA',
    appId: '1:976995616353:android:5511daf5822c825e874c20',
    messagingSenderId: '976995616353',
    projectId: 'safeher-5d770',
    storageBucket: 'safeher-5d770.firebasestorage.app',
  );
}
