import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/firebase_auth_repository.dart';
import '../../domain/models/app_user.dart';
import '../controllers/auth_controller.dart';
import '../controllers/auth_state.dart';

/// Provider cung cấp instance của [AuthRepository].
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository();
});

/// Provider quản lý [AuthController] điều khiển toàn bộ trạng thái Auth.
final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    final repository = ref.watch(authRepositoryProvider);
    return AuthController(repository);
  },
);

/// Provider tiện ích giúp truy xuất nhanh thông tin [AppUser] hiện tại.
final authStateProvider = Provider<AppUser>((ref) {
  return ref.watch(authControllerProvider).user;
});
