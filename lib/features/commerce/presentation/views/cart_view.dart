import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../providers/commerce_providers.dart';

class CartView extends ConsumerWidget {
  const CartView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartControllerProvider);
    final theme = Theme.of(context);
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      appBar: AppBar(title: const Text('Giỏ hàng')),
      body: cartState.isLoading && cartState.items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : cartState.items.isEmpty
              ? const EmptyView(
                  title: 'Giỏ hàng trống',
                  description: 'Hãy dạo quanh cửa hàng và chọn sản phẩm nhé!',
                  icon: Icons.shopping_cart_outlined,
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: cartState.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final item = cartState.items[index];
                    return _CartItemTile(item: item);
                  },
                ),
      bottomNavigationBar: cartState.items.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? AppColors.surfaceDark : Colors.white,
                boxShadow: const [BoxShadow(color: AppColors.shadowColor, blurRadius: 10, offset: Offset(0, -4))],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tạm tính:', style: theme.textTheme.bodyMedium),
                          Text(
                            currencyFormatter.format(cartState.totalAmount),
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppButton(
                      text: 'Thanh toán',
                      onPressed: () => context.push('/checkout'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _CartItemTile extends ConsumerWidget {
  final item;
  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: Image.network(
                item.imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(width: 80, height: 80, color: Colors.grey[200]),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('${item.size} | ${item.color}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormatter.format(item.price),
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () => ref.read(cartControllerProvider.notifier).updateQuantity(item.id, item.quantity - 1),
                ),
                Text('${item.quantity}'),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => ref.read(cartControllerProvider.notifier).updateQuantity(item.id, item.quantity + 1),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
