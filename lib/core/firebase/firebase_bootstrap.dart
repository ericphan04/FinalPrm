import 'dart:io' show Platform;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import '../../firebase_options.dart';
import '../logging/app_logger.dart';
import 'firebase_seed.dart';

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

      // 2. Kiểm tra cờ sử dụng Emulator (phải bật tường minh bằng --dart-define=USE_EMULATOR=true)
      const bool useEmulator = bool.fromEnvironment(
        'USE_EMULATOR',
        defaultValue: false,
      );

      if (useEmulator) {
        String host = 'localhost';
        if (!kIsWeb) {
          host = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
        }

        AppLogger.info('Đang kết nối đến Firebase Emulators tại $host...');

        // Cấu hình Auth Emulator
        await FirebaseAuth.instance.useAuthEmulator(host, 9099);

        // Cấu hình Firestore Emulator
        FirebaseFirestore.instance.settings = Settings(
          host: '$host:8090',
          sslEnabled: false,
          persistenceEnabled: false,
        );

        // Cấu hình Storage Emulator
        await FirebaseStorage.instance.useStorageEmulator(host, 9199);

        // Cấu hình Functions Emulator
        FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);

        AppLogger.info(
          'Kết nối Firebase Local Emulators thành công (Auth: 9099, Firestore: 8090, Storage: 9199)',
        );

        // Tự động nạp dữ liệu mẫu lên Emulator
        Future.delayed(const Duration(milliseconds: 500), () async {
          try {
            await FirebaseSeed.seedAll();
            AppLogger.info(
              'Tự động nạp dữ liệu mẫu (Seed Data) lên Emulator thành công!',
            );
          } catch (e) {
            AppLogger.error('Lỗi khi tự động nạp dữ liệu mẫu: $e');
          }
        });
      } else {
        AppLogger.info(
          kDebugMode
              ? 'Firebase khởi tạo thành công (Debug → dùng project thật). Thêm --dart-define=USE_EMULATOR=true để dùng emulator.'
              : 'Firebase khởi tạo thành công (Production)',
        );
      }
    } catch (e) {
      AppLogger.error('Lỗi xảy ra trong quá trình khởi tạo Firebase', e);
    }
  }
}
