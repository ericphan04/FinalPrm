import '../../domain/models/app_user.dart';

/// Đại diện cho trạng thái xác thực trên giao diện người dùng.
class AuthState {
  final AppUser user;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    required this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  AuthState copyWith({AppUser? user, bool? isLoading, String? errorMessage}) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  String toString() =>
      'AuthState(user: ${user.uid}, isLoading: $isLoading, error: $errorMessage)';
}
