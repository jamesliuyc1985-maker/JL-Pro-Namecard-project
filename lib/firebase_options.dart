import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBlC715Q8Og_3uatXX9FSb0XrOWeMjsXsc',
    appId: '1:719651871406:web:582df7f5ffc89d701dab3f',
    messagingSenderId: '719651871406',
    projectId: 'deal-navigator-crm-120d2',
    authDomain: 'deal-navigator-crm-120d2.firebaseapp.com',
    storageBucket: 'deal-navigator-crm-120d2.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBlC715Q8Og_3uatXX9FSb0XrOWeMjsXsc',
    appId: '1:719651871406:android:66334c6656f66149bc31ef',
    messagingSenderId: '719651871406',
    projectId: 'deal-navigator-crm-120d2',
    storageBucket: 'deal-navigator-crm-120d2.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBlC715Q8Og_3uatXX9FSb0XrOWeMjsXsc',
    appId: '1:719651871406:ios:placeholder',
    messagingSenderId: '719651871406',
    projectId: 'deal-navigator-crm-120d2',
    storageBucket: 'deal-navigator-crm-120d2.firebasestorage.app',
    iosBundleId: 'com.dealnavigator.crm',
  );
}
