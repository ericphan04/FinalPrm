import 'package:flutter/foundation.dart';

/// Logger thông minh lọc bỏ các thông tin định danh cá nhân (PII) như email, số điện thoại
/// trước khi in ra console hoặc gửi lên crash reporting.
class AppLogger {
  AppLogger._();

  static final RegExp _emailRegex = RegExp(
    r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
  );

  static final RegExp _phoneRegex = RegExp(r'(?:\+?84|0)(?:\s*\d){9,10}');

  /// Lọc và ẩn thông tin nhạy cảm (PII) trong chuỗi văn bản.
  static String sanitize(String message) {
    var sanitized = message;

    // Che Email
    sanitized = sanitized.replaceAllMapped(_emailRegex, (match) {
      final email = match.group(0) ?? '';
      final parts = email.split('@');
      if (parts.length == 2) {
        final username = parts[0];
        final domain = parts[1];
        if (username.length > 2) {
          return '${username.substring(0, 2)}***@$domain';
        }
        return '***@$domain';
      }
      return '***';
    });

    // Che Số điện thoại
    sanitized = sanitized.replaceAllMapped(_phoneRegex, (match) {
      final phone = match.group(0) ?? '';
      if (phone.length > 4) {
        return '${phone.substring(0, phone.length - 4)}****';
      }
      return '****';
    });

    return sanitized;
  }

  /// Ghi log thông tin chung
  static void info(String message) {
    if (kDebugMode) {
      debugPrint('[INFO] ${sanitize(message)}');
    }
  }

  /// Ghi log cảnh báo
  static void warning(String message) {
    if (kDebugMode) {
      debugPrint('[WARNING] ${sanitize(message)}');
    }
  }

  /// Ghi log lỗi kèm stacktrace
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('[ERROR] ${sanitize(message)}');
      if (error != null) {
        debugPrint('[ERROR DETAILS] ${sanitize(error.toString())}');
      }
      if (stackTrace != null) {
        debugPrint('[STACKTRACE]\n$stackTrace');
      }
    }
  }
}
