import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/models/app_user_role.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/profile/presentation/views/about_view.dart';
import '../../features/profile/presentation/views/help_view.dart';
import '../../features/profile/presentation/views/profile_view.dart';

// Authentication Views
import '../../features/auth/presentation/views/login_view.dart';
import '../../features/auth/presentation/views/register_view.dart';
import '../../features/auth/presentation/views/forgot_password_view.dart';
import '../../features/auth/presentation/views/mock_screens.dart';

import '../../main.dart' show ShowroomScreen;

/// Lớp chuyển đổi Stream thành [Listenable] cho GoRouter lắng nghe sự thay đổi
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(authRepository.authStateChanges),
    redirect: (context, state) {
      final user = ref.read(authStateProvider);
      final isGuest = user.role == AppUserRole.guest;

      final isLogin = state.matchedLocation == '/login';
      final isRegister = state.matchedLocation == '/register';
      final isForgotPassword = state.matchedLocation == '/forgot-password';

      // 1. Nếu chưa đăng nhập (Guest)
      if (isGuest) {
        // Cho phép truy cập trang đăng nhập, đăng ký, quên mật khẩu và các trang giới thiệu công khai
        if (isLogin ||
            isRegister ||
            isForgotPassword ||
            state.matchedLocation == '/about' ||
            state.matchedLocation == '/help') {
          return null;
        }
        // Các trang khác (như profile, dashboard) yêu cầu đăng nhập
        return '/login';
      }

      // 2. Nếu đã đăng nhập thành công
      // Không cho phép quay lại trang login/register/forgot-password
      if (isLogin || isRegister || isForgotPassword) {
        return '/';
      }

      // Kiểm tra quyền hạn truy cập theo Role
      final path = state.matchedLocation;
      if (path.startsWith('/admin') && user.role != AppUserRole.admin) {
        // Cố tình vào trang admin nhưng không phải admin -> Về trang chủ
        return '/';
      }
      if (path.startsWith('/seller') &&
          user.role != AppUserRole.seller &&
          user.role != AppUserRole.admin) {
        // Cố tình vào trang seller nhưng không có quyền seller/admin -> Về trang chủ
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const ShowroomScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileView(),
      ),
      GoRoute(path: '/about', builder: (context, state) => const AboutView()),
      GoRoute(path: '/help', builder: (context, state) => const HelpView()),
      GoRoute(
        path: '/seller/dashboard',
        builder: (context, state) => const SellerDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
    ],
  );
});
