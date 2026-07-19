import '../../../../core/result/result.dart';
import '../../domain/models/app_user.dart';

/// Interface quản lý các tác vụ xác thực và thông tin phân quyền người dùng.
abstract class AuthRepository {
  /// Theo dõi sự thay đổi của trạng thái đăng nhập.
  Stream<AppUser> get authStateChanges;

  /// Đăng nhập bằng Email và Mật khẩu.
  Future<Result<AppUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Đăng ký tài khoản mới bằng Email, Mật khẩu và Tên hiển thị.
  Future<Result<AppUser>> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  });

  /// Đăng xuất khỏi hệ thống.
  Future<Result<void>> signOut();

  /// Gửi email khôi phục mật khẩu.
  Future<Result<void>> sendPasswordResetEmail({required String email});

  /// Lấy thông tin người dùng hiện tại (nếu có).
  Future<Result<AppUser>> getCurrentUser();

  /// Ép buộc làm mới (force refresh) ID Token để cập nhật các Claims phân quyền mới.
  Future<Result<void>> forceRefreshIdToken();

  /// Đổi mật khẩu cho người dùng hiện tại (yêu cầu mật khẩu cũ để xác thực lại).
  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}
