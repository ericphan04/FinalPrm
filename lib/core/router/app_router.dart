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

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final user = ref.read(authStateProvider);
      final isGuest = user.role == AppUserRole.guest;

      final isLogin = state.uri.path == '/login';
      final isRegister = state.uri.path == '/register';
      final isForgotPassword = state.uri.path == '/forgot-password';

      // 1. Nếu chưa đăng nhập (Guest)
      if (isGuest) {
        // Cho phép truy cập trang đăng nhập, đăng ký, quên mật khẩu và các trang giới thiệu công khai
        if (isLogin ||
            isRegister ||
            isForgotPassword ||
            state.uri.path == '/about' ||
            state.uri.path == '/help') {
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
      final path = state.uri.path;
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

  // Lắng nghe sự thay đổi của authStateProvider để trigger GoRouter refresh
  ref.listen(authStateProvider, (previous, next) {
    if (previous != next) {
      router.refresh();
    }
  });

  return router;
});
