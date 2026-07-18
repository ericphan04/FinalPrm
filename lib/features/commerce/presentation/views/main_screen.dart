import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/navigation_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

import 'tabs/home_tab.dart';
import 'tabs/shop_tab.dart';
import 'tabs/bag_tab.dart';
import '../../../profile/presentation/views/tabs/profile_tab.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(mainTabIndexProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Tabs
    final tabs = [
      const HomeTab(),
      const ShopTab(),
      const BagTab(),
      const ProfileTab(),
    ];

    // Background color of the floating bar changes based on current tab
    // Tab 0 (Home) has dark background. Others have white/light background.
    final bool isHome = currentIndex == 0;
    final navBarBgColor = isHome
        ? Colors.black.withOpacity(0.5)
        : (isDark ? AppColors.surfaceDark : Colors.white).withOpacity(0.85);
    final navBarTextColor = isHome
        ? Colors.white
        : (isDark ? Colors.white : Colors.black);
    final navBarUnselectedColor = isHome
        ? Colors.white54
        : (isDark ? Colors.white54 : Colors.black54);

    return Scaffold(
      extendBody: true, // Cho phép body chìm dưới BottomNavBar
      body: IndexedStack(index: currentIndex, children: tabs),
      // Bố trí thanh điều hướng giả lập
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Row(
          children: [
            // Thanh Pill chứa 4 tabs
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    height: 64,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: navBarBgColor,
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(
                          0,
                          Icons.home_outlined,
                          Icons.home_rounded,
                          'Home',
                          currentIndex,
                          ref,
                          navBarTextColor,
                          navBarUnselectedColor,
                        ),
                        _buildNavItem(
                          1,
                          Icons.shopping_cart_outlined,
                          Icons.shopping_cart_rounded,
                          'Shop',
                          currentIndex,
                          ref,
                          navBarTextColor,
                          navBarUnselectedColor,
                        ),
                        _buildNavItem(
                          2,
                          Icons.shopping_bag_outlined,
                          Icons.shopping_bag_rounded,
                          'Bag',
                          currentIndex,
                          ref,
                          navBarTextColor,
                          navBarUnselectedColor,
                        ),
                        _buildNavItem(
                          3,
                          Icons.person_outline_rounded,
                          Icons.person_rounded,
                          'Profile',
                          currentIndex,
                          ref,
                          navBarTextColor,
                          navBarUnselectedColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Nút Search độc lập
            ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: GestureDetector(
                  onTap: () {
                    // Mở màn hình Search hoặc Focus
                  },
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: navBarBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.search_rounded, color: navBarTextColor),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData unselectedIcon,
    IconData selectedIcon,
    String label,
    int currentIndex,
    WidgetRef ref,
    Color selectedColor,
    Color unselectedColor,
  ) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        ref.read(mainTabIndexProvider.notifier).state = index;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                color: Colors.grey.withOpacity(
                  0.3,
                ), // Hiệu ứng nền xám khi được chọn
                borderRadius: BorderRadius.circular(20),
              )
            : const BoxDecoration(color: Colors.transparent),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? selectedIcon : unselectedIcon,
              color: isSelected ? selectedColor : unselectedColor,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? selectedColor : unselectedColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
