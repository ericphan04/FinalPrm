import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/product_card_skeleton.dart';
import '../providers/commerce_providers.dart';
import 'widgets/product_card.dart';

class ProductListView extends ConsumerWidget {
  const ProductListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogState = ref.watch(catalogControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catalog'),
        centerTitle: false,
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final cartState = ref.watch(cartControllerProvider);
              final itemCount = cartState.items.fold<int>(
                0,
                (sum, item) => sum + item.quantity,
              );

              return IconButton(
                tooltip: 'Giỏ hàng',
                icon: Badge(
                  isLabelVisible: itemCount > 0,
                  label: Text(itemCount.toString()),
                  child: const Icon(Icons.shopping_bag_outlined),
                ),
                onPressed: () => context.push('/cart'),
              );
            },
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: _CatalogBody(catalogState: catalogState),
    );
  }
}

class _CatalogBody extends ConsumerWidget {
  final dynamic catalogState;

  const _CatalogBody({required this.catalogState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (catalogState.isLoading && catalogState.products.isEmpty) {
      return GridView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 0.64,
        ),
        itemCount: 6,
        itemBuilder: (context, index) => const ProductCardSkeleton(),
      );
    }

    if (catalogState.errorMessage != null && catalogState.products.isEmpty) {
      return ErrorView(
        onRetry: () => ref
            .read(catalogControllerProvider.notifier)
            .filterByCategory(catalogState.selectedCategoryId),
      );
    }

    if (catalogState.products.isEmpty) {
      return const EmptyView(
        title: 'Chưa có sản phẩm',
        description: 'Sản phẩm mới sẽ hiển thị khi danh mục được cập nhật.',
        icon: Icons.inventory_2_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(catalogControllerProvider.notifier)
            .filterByCategory(catalogState.selectedCategoryId);
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 0.64,
        ),
        itemCount: catalogState.products.length,
        itemBuilder: (context, index) {
          final product = catalogState.products[index];
          return ProductCard(
            product: product,
            onTap: () => context.push('/product/${product.id}'),
          );
        },
      ),
    );
  }
}
