import 'package:firebase_auth/firebase_auth.dart';
import 'app_failure.dart';

/// Bộ chuyển đổi (mapping) các exception hệ thống sang [AppFailure] tiếng Việt thân thiện.
class ErrorHandler {
  ErrorHandler._();

  static AppFailure handle(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'wrong-password':
        case 'invalid-credential':
        case 'INVALID_LOGIN_CREDENTIALS':
          return AppFailure(
            code: error.code,
            message: 'Mật khẩu hoặc thông tin đăng nhập không chính xác.',
            originalError: error,
          );
        case 'user-not-found':
          return AppFailure(
            code: error.code,
            message: 'Tài khoản email này chưa được đăng ký.',
            originalError: error,
          );
        case 'email-already-in-use':
          return AppFailure(
            code: error.code,
            message: 'Địa chỉ email này đã được đăng ký tài khoản khác.',
            originalError: error,
          );
        case 'weak-password':
          return AppFailure(
            code: error.code,
            message:
                'Mật khẩu quá yếu. Vui lòng đặt mật khẩu từ 6 ký tự trở lên.',
            originalError: error,
          );
        case 'invalid-email':
          return AppFailure(
            code: error.code,
            message: 'Định dạng địa chỉ email không hợp lệ.',
            originalError: error,
          );
        case 'user-disabled':
          return AppFailure(
            code: error.code,
            message: 'Tài khoản của bạn đã bị khóa hoặc vô hiệu hóa.',
            originalError: error,
          );
        case 'requires-recent-login':
          return AppFailure(
            code: error.code,
            message: 'Vui lòng đăng nhập lại trước khi thực hiện thao tác này.',
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
            message:
                'Lỗi kết nối mạng. Vui lòng kiểm tra lại đường truyền internet.',
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
