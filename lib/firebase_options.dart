// File generated from Firebase project: shoestoremarketplace
// DO NOT COMMIT THIS FILE — it is listed in .gitignore
// To regenerate: run `flutterfire configure` or `firebase apps:sdkconfig`

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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions không hỗ trợ nền tảng này.',
        );
    }
  }

  // Android — lấy từ: firebase apps:sdkconfig ANDROID

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCiAWCWokDMAKDOeI1fKBanXSBju13RjMs',
    appId: '1:1085757977903:android:c61581b4d421577d5fddda',
    messagingSenderId: '1085757977903',
    projectId: 'shoestoremarketplace',
    storageBucket: 'shoestoremarketplace.firebasestorage.app',
  );
  // iOS — cần chạy `flutterfire configure` hoặc tải GoogleService-Info.plist thủ công
  // Tạm dùng cùng projectId; thay thế apiKey + appId khi có iOS app đăng ký trên Firebase Console
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCiAWCWokDMAKDOeI1fKBanXSBju13RjMs',
    appId: '1:1085757977903:ios:000000000000000000000000', // TODO: thay bằng iOS appId thật
    messagingSenderId: '1085757977903',
    projectId: 'shoestoremarketplace',
    storageBucket: 'shoestoremarketplace.firebasestorage.app',
    iosClientId:
        '1085757977903-3jld0ckr8oego1mvm8tt693f4284mnd1.apps.googleusercontent.com',
    iosBundleId: 'com.example.finalprm',
  );

  // Web — chưa cấu hình, thêm nếu cần deploy web
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCiAWCWokDMAKDOeI1fKBanXSBju13RjMs',
    appId: '1:1085757977903:web:000000000000000000000000', // TODO: thay bằng Web appId thật
    messagingSenderId: '1085757977903',
    projectId: 'shoestoremarketplace',
    storageBucket: 'shoestoremarketplace.firebasestorage.app',
  );
}
