import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/empty_view.dart';
import '../providers/commerce_providers.dart';

class CartView extends ConsumerWidget {
  const CartView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartControllerProvider);
    final theme = Theme.of(context);
    final currencyFormatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
    );
    const shippingFee = 250000.0;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Giỏ hàng',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '${cartState.items.length} sản phẩm',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: cartState.isLoading && cartState.items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : cartState.items.isEmpty
          ? const EmptyView(
              title: 'Giỏ hàng đang trống',
              description: 'Xem cửa hàng và thêm sản phẩm đầu tiên của bạn.',
              icon: Icons.shopping_bag_outlined,
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              itemCount: cartState.items.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final item = cartState.items[index];
                return _CartItemTile(item: item);
              },
            ),
      bottomNavigationBar: cartState.items.isEmpty
          ? null
          : _CheckoutPanel(
              subtotal: currencyFormatter.format(cartState.totalAmount),
              shipping: currencyFormatter.format(shippingFee),
              total: currencyFormatter.format(
                cartState.totalAmount + shippingFee,
              ),
              onCheckout: () => context.push('/checkout'),
            ),
    );
  }
}

class _CheckoutPanel extends StatelessWidget {
  final String subtotal;
  final String shipping;
  final String total;
  final VoidCallback onCheckout;

  const _CheckoutPanel({
    required this.subtotal,
    required this.shipping,
    required this.total,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AmountRow(label: 'Tạm tính', value: subtotal),
            const SizedBox(height: AppSpacing.xs),
            _AmountRow(label: 'Phí giao hàng', value: shipping),
            const Divider(height: AppSpacing.lg),
            _AmountRow(label: 'Tổng cộng', value: total, strong: true),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              text: 'Thanh toán',
              width: double.infinity,
              icon: const Icon(Icons.lock_outline_rounded, size: 18),
              onPressed: onCheckout,
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  final String label;
  final String value;
  final bool strong;

  const _AmountRow({
    required this.label,
    required this.value,
    this.strong = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Text(
          label,
          style: strong
              ? theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                )
              : theme.textTheme.bodyMedium,
        ),
        const Spacer(),
        Text(
          value,
          style: strong
              ? theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                )
              : theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _CartItemTile extends ConsumerWidget {
  final dynamic item;

  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: Image.network(
              item.imageUrl,
              width: 88,
              height: 88,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 88,
                height: 88,
                color: isDark ? AppColors.borderDark : AppColors.primaryLight,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${item.size} / ${item.color}',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  currencyFormatter.format(item.price),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.remove_rounded, size: 18),
                  onPressed: () => ref
                      .read(cartControllerProvider.notifier)
                      .updateQuantity(item.id, item.quantity - 1),
                ),
                Text('${item.quantity}', style: theme.textTheme.labelLarge),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  onPressed: () => ref
                      .read(cartControllerProvider.notifier)
                      .updateQuantity(item.id, item.quantity + 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
