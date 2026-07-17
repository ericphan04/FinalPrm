import 'dart:io' show Platform;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import '../../firebase_options.dart';
import '../logging/app_logger.dart';

/// Lớp điều khiển khởi tạo Firebase và cấu hình kết nối Emulator.
class FirebaseBootstrap {
  FirebaseBootstrap._();

  /// Khởi chạy cấu hình Firebase
  static Future<void> initialize() async {
    try {
      // 1. Khởi tạo Firebase Core với options
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // 2. Kiểm tra cờ sử dụng Emulator
      const bool forceEmulator = bool.fromEnvironment(
        'USE_EMULATOR',
        defaultValue: false,
      );

      // Mặc định kết nối Emulator nếu ở chế độ Debug hoặc bật cờ
      if (kDebugMode || forceEmulator) {
        String host = 'localhost';
        if (!kIsWeb) {
          host = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
        }

        AppLogger.info('Đang kết nối đến Firebase Emulators tại $host...');

        // Cấu hình Auth Emulator
        await FirebaseAuth.instance.useAuthEmulator(host, 9099);

        // Cấu hình Firestore Emulator
        FirebaseFirestore.instance.settings = Settings(
          host: '$host:8080',
          sslEnabled: false,
          persistenceEnabled: false,
        );

        // Cấu hình Storage Emulator
        await FirebaseStorage.instance.useStorageEmulator(host, 9199);

        AppLogger.info(
          'Kết nối thành công Firebase Local Emulators (Auth: 9099, Firestore: 8080, Storage: 9199)',
        );
      } else {
        AppLogger.info('Khởi tạo Firebase thành công (Chế độ Production)');
      }
    } catch (e) {
      AppLogger.error('Lỗi xảy ra trong quá trình khởi tạo Firebase', e);
    }
  }
}
