import '../error/app_failure.dart';

/// Một sealed class đại diện cho kết quả của một tác vụ,
/// có thể là thành công [Success] hoặc thất bại [Failure].
sealed class Result<T> {
  const Result();

  /// Tiện ích chuyển đổi hoặc thao tác trên kết quả
  R when<R>({
    required R Function(T data) onSuccess,
    required R Function(AppFailure failure) onFailure,
  }) {
    if (this is Success<T>) {
      return onSuccess((this as Success<T>).data);
    } else if (this is Failure<T>) {
      return onFailure((this as Failure<T>).failure);
    }
    throw StateError('Result không thuộc loại Success hay Failure đã biết');
  }
}

/// Đại diện cho kết quả thành công chứa dữ liệu kiểu [T].
class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

/// Đại diện cho kết quả thất bại chứa thông tin lỗi [AppFailure].
class Failure<T> extends Result<T> {
  final AppFailure failure;
  const Failure(this.failure);
}
