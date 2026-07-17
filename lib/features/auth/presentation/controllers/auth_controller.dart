import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/models/app_user.dart';
import 'auth_state.dart';

/// StateNotifier điều khiển logic xác thực và cập nhật trạng thái UI.
class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  StreamSubscription<AppUser>? _subscription;

  AuthController(this._repository) : super(AuthState(user: AppUser.guest())) {
    _init();
  }

  void _init() {
    state = state.copyWith(isLoading: true);
    // Lắng nghe thay đổi trạng thái xác thực từ Repository.
    _subscription = _repository.authStateChanges.listen(
      (appUser) {
        state = AuthState(user: appUser, isLoading: false);
      },
      onError: (err) {
        state = AuthState(
          user: AppUser.guest(),
          isLoading: false,
          errorMessage: 'Lỗi đồng bộ phiên đăng nhập: ${err.toString()}',
        );
      },
    );
  }

  /// Đăng nhập email/password
  Future<void> signIn({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _repository.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    result.when(
      onSuccess: (user) {
        state = state.copyWith(user: user, isLoading: false);
      },
      onFailure: (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
      },
    );
  }

  /// Đăng ký tài khoản mới
  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _repository.signUpWithEmailAndPassword(
      email: email,
      password: password,
      displayName: displayName,
    );
    result.when(
      onSuccess: (user) {
        state = state.copyWith(user: user, isLoading: false);
      },
      onFailure: (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
      },
    );
  }

  /// Đăng xuất khỏi hệ thống
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _repository.signOut();
    result.when(
      onSuccess: (_) {
        state = AuthState(user: AppUser.guest(), isLoading: false);
      },
      onFailure: (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
      },
    );
  }

  /// Yêu cầu gửi email khôi phục mật khẩu
  Future<bool> sendPasswordReset({required String email}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _repository.sendPasswordResetEmail(email: email);
    return result.when(
      onSuccess: (_) {
        state = state.copyWith(isLoading: false);
        return true;
      },
      onFailure: (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
    );
  }

  /// Force refresh token để lấy Custom Claims mới nhất sau khi thay đổi quyền từ backend
  Future<void> refreshUserRole() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final refreshResult = await _repository.forceRefreshIdToken();
    await refreshResult.when(
      onSuccess: (_) async {
        final userResult = await _repository.getCurrentUser();
        userResult.when(
          onSuccess: (user) {
            state = state.copyWith(user: user, isLoading: false);
          },
          onFailure: (failure) {
            state = state.copyWith(
              isLoading: false,
              errorMessage: failure.message,
            );
          },
        );
      },
      onFailure: (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
