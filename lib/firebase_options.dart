import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDvKxnoft_2XLdkeLUfTOPyseRqeUQ6wTY',
    authDomain: 'deal-navigator-crm.firebaseapp.com',
    projectId: 'deal-navigator-crm',
    storageBucket: 'deal-navigator-crm.firebasestorage.app',
    messagingSenderId: '916821158334',
    appId: '1:916821158334:web:dbd50a5a8425fc0abc31ef',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAWwM3-yEkz-1IAp0xLTRedqpQHp49Yfno',
    projectId: 'deal-navigator-crm',
    storageBucket: 'deal-navigator-crm.firebasestorage.app',
    messagingSenderId: '916821158334',
    appId: '1:916821158334:android:66334c6656f66149bc31ef',
  );
}
