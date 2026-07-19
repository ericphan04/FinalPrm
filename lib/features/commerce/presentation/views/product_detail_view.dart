import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/commerce_providers.dart';
import '../../domain/models/cart_item.dart';

class ProductDetailView extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailView({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends ConsumerState<ProductDetailView> {
  String? selectedSize;
  String? selectedColor;
  int quantity = 1;

  @override
  Widget build(BuildContext context) {
    final catalogState = ref.watch(catalogControllerProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final product = catalogState.products.firstWhere(
      (p) => p.id == widget.productId,
      orElse: () => throw Exception('Product not found'),
    );

    final currencyFormatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
    );

    // Find matching variant if size & color selected
    final variant = product.variants
        .where((v) => v.size == selectedSize && v.color == selectedColor)
        .firstOrNull;
    final currentPrice = product.basePrice + (variant?.priceDifference ?? 0);
    final displayPrice = currencyFormatter.format(currentPrice);

    final sizes = product.variants.map((e) => e.size).toSet().toList();
    final colors = product.variants.map((e) => e.color).toSet().toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        actions: [
          Consumer(
            builder: (context, ref, _) {
              // Watch state so it rebuilds when favorites change
              ref.watch(favoriteControllerProvider);
              final isFavorite = ref
                  .read(favoriteControllerProvider.notifier)
                  .isFavorite(product.id);

              return IconButton(
                icon: Icon(
                  isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: isFavorite ? Colors.redAccent : null,
                ),
                onPressed: () {
                  ref
                      .read(favoriteControllerProvider.notifier)
                      .toggleFavorite(product.id);
                },
              );
            },
          ),
          Consumer(
            builder: (context, ref, _) {
              final cartState = ref.watch(cartControllerProvider);
              final itemCount = cartState.items.fold(
                0,
                (sum, item) => sum + item.quantity,
              );

              return IconButton(
                icon: Badge(
                  isLabelVisible: itemCount > 0,
                  label: Text(itemCount.toString()),
                  child: const Icon(Icons.shopping_cart_outlined),
                ),
                onPressed: () => context.push('/cart'),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'product-${product.id}',
              child: Image.network(
                product.images.isNotEmpty
                    ? product.images.first
                    : 'https://via.placeholder.com/600',
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(height: 300, color: Colors.grey[200]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    displayPrice,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Size Selection
                  if (sizes.isNotEmpty) ...[
                    Text('Kích thước', style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      children: sizes.map((s) {
                        final isSelected = selectedSize == s;
                        return ChoiceChip(
                          label: Text(s),
                          selected: isSelected,
                          onSelected: (val) {
                            setState(() {
                              selectedSize = val ? s : null;
                            });
                          },
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white : Colors.black),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // Color Selection
                  if (colors.isNotEmpty) ...[
                    Text('Màu sắc', style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      children: colors.map((c) {
                        final isSelected = selectedColor == c;
                        return ChoiceChip(
                          label: Text(c),
                          selected: isSelected,
                          onSelected: (val) {
                            setState(() {
                              selectedColor = val ? c : null;
                            });
                          },
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white : Colors.black),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  Text('Mô tả', style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  Text(product.description, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 10,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Quantity control
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.borderLight),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: quantity > 1
                          ? () => setState(() => quantity--)
                          : null,
                    ),
                    Text('$quantity', style: theme.textTheme.titleMedium),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => setState(() => quantity++),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppButton(
                  text: 'Thêm vào giỏ',
                  onPressed: (selectedSize == null || selectedColor == null)
                      ? null
                      : () {
                          if (variant == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Phân loại không hợp lệ'),
                              ),
                            );
                            return;
                          }
                          if (variant.stockQuantity < quantity) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Không đủ số lượng trong kho'),
                              ),
                            );
                            return;
                          }
                          final item = CartItem(
                            id: '',
                            productId: product.id,
                            variantId: variant.id,
                            productName: product.name,
                            imageUrl: product.images.isNotEmpty
                                ? product.images.first
                                : '',
                            size: selectedSize!,
                            color: selectedColor!,
                            price: currentPrice,
                            quantity: quantity,
                            addedAt: DateTime.now(),
                          );
                          ref
                              .read(cartControllerProvider.notifier)
                              .addToCart(item);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã thêm vào giỏ hàng'),
                            ),
                          );
                        },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
