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

  // 新项目: deal-navigator-crm (project ID: deal-navigator-crm-a2caa)
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAUyHSgTbWX13xRvVE1vxU0bjUai8rpyUk',
    appId: '1:67466347291:web:fb741cf334a00409ec89be',
    messagingSenderId: '67466347291',
    projectId: 'deal-navigator-crm-a2caa',
    authDomain: 'deal-navigator-crm-a2caa.firebaseapp.com',
    storageBucket: 'deal-navigator-crm-a2caa.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAUyHSgTbWX13xRvVE1vxU0bjUai8rpyUk',
    appId: '1:67466347291:android:placeholder',
    messagingSenderId: '67466347291',
    projectId: 'deal-navigator-crm-a2caa',
    storageBucket: 'deal-navigator-crm-a2caa.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAUyHSgTbWX13xRvVE1vxU0bjUai8rpyUk',
    appId: '1:67466347291:ios:placeholder',
    messagingSenderId: '67466347291',
    projectId: 'deal-navigator-crm-a2caa',
    storageBucket: 'deal-navigator-crm-a2caa.firebasestorage.app',
    iosBundleId: 'com.dealnavigator.crm',
  );
}
