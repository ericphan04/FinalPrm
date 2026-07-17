import 'package:firebase_auth/firebase_auth.dart';
import 'app_failure.dart';

/// Bộ chuyển đổi (mapping) các exception hệ thống sang [AppFailure] tiếng Việt thân thiện.
class ErrorHandler {
  ErrorHandler._();

  static AppFailure handle(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return AppFailure(
            code: error.code,
            message: 'Tài khoản không tồn tại trên hệ thống.',
            originalError: error,
          );
        case 'wrong-password':
          return AppFailure(
            code: error.code,
            message: 'Mật khẩu đăng nhập không chính xác.',
            originalError: error,
          );
        case 'email-already-in-use':
          return AppFailure(
            code: error.code,
            message: 'Địa chỉ email này đã được sử dụng bởi tài khoản khác.',
            originalError: error,
          );
        case 'weak-password':
          return AppFailure(
            code: error.code,
            message: 'Mật khẩu quá yếu. Vui lòng sử dụng tối thiểu 6 ký tự.',
            originalError: error,
          );
        case 'invalid-email':
          return AppFailure(
            code: error.code,
            message: 'Định dạng địa chỉ email không hợp lệ.',
            originalError: error,
          );
        case 'operation-not-allowed':
          return AppFailure(
            code: error.code,
            message: 'Phương thức đăng nhập này chưa được kích hoạt.',
            originalError: error,
          );
        case 'too-many-requests':
          return AppFailure(
            code: error.code,
            message:
                'Tài khoản bị tạm khóa do gửi quá nhiều yêu cầu. Vui lòng thử lại sau ít phút.',
            originalError: error,
          );
        case 'network-request-failed':
          return AppFailure(
            code: error.code,
            message: 'Lỗi kết nối mạng. Vui lòng kiểm tra lại thiết bị.',
            originalError: error,
          );
        default:
          return AppFailure(
            code: error.code,
            message: error.message ?? 'Đã xảy ra lỗi xác thực hệ thống.',
            originalError: error,
          );
      }
    }

    if (error is FirebaseException) {
      return AppFailure(
        code: error.code,
        message: 'Lỗi dịch vụ Firebase (${error.code}): ${error.message}',
        originalError: error,
      );
    }

    // Nếu đã là AppFailure thì trả về luôn
    if (error is AppFailure) {
      return error;
    }

    return AppFailure(
      code: 'unknown_error',
      message: 'Đã xảy ra lỗi không xác định. Vui lòng thử lại.',
      originalError: error,
    );
  }
}
