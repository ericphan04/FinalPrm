import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/product_card_skeleton.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/empty_view.dart';
import '../providers/commerce_providers.dart';
import 'widgets/product_card.dart';

class ProductListView extends ConsumerWidget {
  const ProductListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogState = ref.watch(catalogControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cửa hàng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => context.push('/cart'),
          ),
        ],
      ),
      body: _buildBody(context, catalogState, ref),
    );
  }

  Widget _buildBody(BuildContext context, catalogState, WidgetRef ref) {
    if (catalogState.isLoading && catalogState.products.isEmpty) {
      return GridView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 0.65,
        ),
        itemCount: 6,
        itemBuilder: (context, index) => const ProductCardSkeleton(),
      );
    }

    if (catalogState.errorMessage != null && catalogState.products.isEmpty) {
      return ErrorView(
        onRetry: () => ref.read(catalogControllerProvider.notifier).filterByCategory(catalogState.selectedCategoryId),
      );
    }

    if (catalogState.products.isEmpty) {
      return const EmptyView(
        title: 'Chưa có sản phẩm nào',
        description: 'Chúng tôi đang cập nhật sản phẩm mới. Vui lòng quay lại sau.',
        icon: Icons.inventory_2_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(catalogControllerProvider.notifier).filterByCategory(catalogState.selectedCategoryId);
      },
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.md),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 0.65,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final product = catalogState.products[index];
                  return ProductCard(
                    product: product,
                    onTap: () => context.push('/product/${product.id}'),
                  );
                },
                childCount: catalogState.products.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
