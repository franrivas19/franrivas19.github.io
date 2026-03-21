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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions no esta configurado para esta plataforma.',
        );
    }
  }

  // Reemplaza estos valores con `flutterfire configure` para conectar Firebase.
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBXq2ugLXlCY6Ot11QIiZvi_0EK4mEnXV4',
    appId: 'REPLACE_ME',
    messagingSenderId: 'REPLACE_ME',
    projectId: 'gambeta-46604',
    authDomain: 'REPLACE_ME',
    storageBucket: 'gambeta-46604.firebasestorage.app',
    measurementId: 'REPLACE_ME',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBXq2ugLXlCY6Ot11QIiZvi_0EK4mEnXV4',
    appId: '1:798602460389:android:eba8fcc3b11aa6bfa3e80c',
    messagingSenderId: 'REPLACE_ME',
    projectId: 'gambeta-46604',
    storageBucket: 'gambeta-46604.firebasestorage.app',
  );
}
