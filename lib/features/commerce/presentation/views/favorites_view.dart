import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_view.dart';
import 'widgets/product_card.dart';
import '../providers/commerce_providers.dart';

class FavoritesView extends ConsumerWidget {
  const FavoritesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteState = ref.watch(favoriteControllerProvider);
    final catalogState = ref.watch(catalogControllerProvider);

    final favoriteProducts = catalogState.products
        .where((p) => favoriteState.favoriteIds.contains(p.id))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: favoriteState.isLoading && favoriteProducts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : favoriteProducts.isEmpty
          ? const EmptyView(
              title: 'No Favorites Yet',
              description: 'Tap the heart icon on a product to save it here.',
              icon: Icons.favorite_border_rounded,
            )
          : GridView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 0.6,
              ),
              itemCount: favoriteProducts.length,
              itemBuilder: (context, index) {
                final product = favoriteProducts[index];
                return ProductCard(
                  product: product,
                  isFavorite: true,
                  onFavoriteToggle: () {
                    ref
                        .read(favoriteControllerProvider.notifier)
                        .toggleFavorite(product.id);
                  },
                  onTap: () => context.push('/product/${product.id}'),
                );
              },
            ),
    );
  }
}
