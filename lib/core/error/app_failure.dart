/// Đại diện cho lỗi hệ thống đồng nhất, thân thiện với người dùng
/// và có mã lỗi ổn định để phục vụ tracking/debugging.
class AppFailure {
  final String code;
  final String message;
  final Object? originalError;

  const AppFailure({
    required this.code,
    required this.message,
    this.originalError,
  });

  @override
  String toString() =>
      'AppFailure(code: $code, message: $message, originalError: $originalError)';
}
