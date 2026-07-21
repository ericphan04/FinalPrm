import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/models/app_user_role.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/profile/presentation/views/about_view.dart';
import '../../features/profile/presentation/views/help_view.dart';
import '../../features/profile/presentation/views/profile_view.dart';
import '../../features/profile/presentation/views/notification_history_view.dart';

// Authentication Views
import '../../features/auth/presentation/views/login_view.dart';
import '../../features/auth/presentation/views/register_view.dart';
import '../../features/auth/presentation/views/forgot_password_view.dart';

import '../../features/admin/presentation/views/admin_dashboard_view.dart';

// Seller Views
import '../../features/seller/presentation/views/seller_apply_view.dart';
import '../../features/seller/presentation/views/seller_center_shell.dart';

import '../../features/commerce/presentation/views/main_screen.dart';

import '../../features/commerce/presentation/views/product_list_view.dart';
import '../../features/commerce/presentation/views/product_detail_view.dart';
import '../../features/commerce/presentation/views/cart_view.dart';
import '../../features/commerce/presentation/views/checkout_view.dart';
import '../../features/commerce/presentation/views/order_list_view.dart';
import '../../features/commerce/presentation/views/favorites_view.dart';
import '../../features/commerce/presentation/views/order_success_view.dart';
import '../../features/commerce/domain/models/app_order.dart';

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
        // Cho phép truy cập trang đăng nhập, đăng ký, quên mật khẩu, trang public và commerce cơ bản
        if (isLogin ||
            isRegister ||
            isForgotPassword ||
            state.uri.path == '/' ||
            state.uri.path == '/about' ||
            state.uri.path == '/help' ||
            state.uri.path.startsWith('/catalog') ||
            state.uri.path.startsWith('/product') ||
            state.uri.path == '/cart' ||
            state.uri.path == '/favorites') {
          return null;
        }
        // Các trang khác (như checkout, orders, profile, dashboard) yêu cầu đăng nhập
        return '/login';
      }

      // 2. Nếu đã đăng nhập thành công
      // Không cho phép quay lại trang login/register/forgot-password
      if (isLogin || isRegister || isForgotPassword) {
        if (user.role == AppUserRole.admin) return '/admin/dashboard';
        if (user.role == AppUserRole.seller) return '/seller/dashboard';
        return '/';
      }

      // Kiểm tra quyền hạn truy cập theo Role
      final path = state.uri.path;
      if (user.role == AppUserRole.admin) {
        return path == '/admin/dashboard' ? null : '/admin/dashboard';
      }
      if (user.role == AppUserRole.seller) {
        return path == '/seller/dashboard' ? null : '/seller/dashboard';
      }
      if (path.startsWith('/admin') && user.role != AppUserRole.admin) {
        // Cố tình vào trang admin nhưng không phải admin -> Về trang chủ
        return '/';
      }
      if ((path.startsWith('/seller/') || path == '/seller') &&
          user.role != AppUserRole.seller) {
        // Cố tình vào trang seller nhưng không có quyền seller/admin -> Về trang chủ
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const MainScreen()),
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
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationHistoryView(),
      ),
      GoRoute(path: '/about', builder: (context, state) => const AboutView()),
      GoRoute(path: '/help', builder: (context, state) => const HelpView()),
      GoRoute(
        path: '/seller/dashboard',
        builder: (context, state) => const SellerCenterShell(),
      ),
      GoRoute(
        path: '/seller-apply',
        builder: (context, state) => const SellerApplyView(),
      ),
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminDashboardView(),
      ),
      GoRoute(
        path: '/catalog',
        builder: (context, state) => const ProductListView(),
      ),
      GoRoute(
        path: '/product/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ProductDetailView(productId: id);
        },
      ),
      GoRoute(path: '/cart', builder: (context, state) => const CartView()),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutView(),
      ),
      GoRoute(
        path: '/orders',
        builder: (context, state) => const OrderListView(),
      ),
      GoRoute(
        path: '/favorites',
        builder: (context, state) => const FavoritesView(),
      ),
      GoRoute(
        path: '/order-success',
        builder: (context, state) {
          final order = state.extra as AppOrder;
          return OrderSuccessView(order: order);
        },
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
