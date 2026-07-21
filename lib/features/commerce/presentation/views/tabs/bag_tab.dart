import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/providers/navigation_providers.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../providers/commerce_providers.dart';
import '../cart_view.dart';

class BagTab extends ConsumerWidget {
  const BagTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartControllerProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (cartState.isLoading && cartState.items.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (cartState.items.isNotEmpty) {
      return const CartView();
    }

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Giỏ hàng'), centerTitle: false),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                  ),
                ),
                child: Icon(
                  Icons.shopping_bag_outlined,
                  size: 34,
                  color: isDark ? Colors.white : AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Giỏ hàng đang trống',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Chọn sản phẩm trong cửa hàng, giỏ hàng của bạn sẽ hiển thị tại đây.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const Spacer(),
              AppButton(
                text: 'Xem cửa hàng',
                width: double.infinity,
                icon: const Icon(Icons.storefront_rounded, size: 18),
                onPressed: () {
                  ref.read(mainTabIndexProvider.notifier).state = 1;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
