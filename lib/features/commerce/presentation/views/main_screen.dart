import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/navigation_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../admin/presentation/views/admin_dashboard_view.dart';
import '../../../auth/domain/models/app_user_role.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../seller/presentation/views/seller_center_shell.dart';
import 'tabs/bag_tab.dart';
import 'tabs/home_tab.dart';
import 'tabs/shop_tab.dart';
import '../../../profile/presentation/views/tabs/profile_tab.dart';
import '../providers/commerce_providers.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider);
    if (user.role == AppUserRole.admin) {
      return const AdminDashboardView();
    }
    if (user.role == AppUserRole.seller) {
      return const SellerCenterShell();
    }

    final currentIndex = ref.watch(mainTabIndexProvider);
    final cartState = ref.watch(cartControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final itemCount = cartState.items.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );

    const tabs = [HomeTab(), ShopTab(), BagTab(), ProfileTab()];

    return Scaffold(
      body: IndexedStack(index: currentIndex, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        height: 72,
        elevation: 0,
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: isDark ? Colors.white : AppColors.primary,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (index) {
          ref.read(mainTabIndexProvider.notifier).state = index;
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Trang chủ',
          ),
          const NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront_rounded),
            label: 'Cửa hàng',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: itemCount > 0,
              label: Text(itemCount.toString()),
              child: const Icon(Icons.shopping_bag_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: itemCount > 0,
              label: Text(itemCount.toString()),
              child: const Icon(Icons.shopping_bag_rounded),
            ),
            label: 'Giỏ hàng',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }
}
