import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/empty_view.dart';
import '../../../../../core/widgets/error_view.dart';
import '../../../../../core/widgets/product_card_skeleton.dart';
import '../../../domain/models/category.dart';
import '../../../domain/models/product.dart';
import '../../controllers/catalog_controller.dart';
import '../../providers/commerce_providers.dart';
import '../widgets/product_card.dart';

class ShopTab extends ConsumerStatefulWidget {
  const ShopTab({super.key});

  @override
  ConsumerState<ShopTab> createState() => _ShopTabState();
}

class _ShopTabState extends ConsumerState<ShopTab> {
  String? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final catalogState = ref.watch(catalogControllerProvider);
    final categories = _normalizedCategories(catalogState);
    final products = _filteredProducts(catalogState.products);
    final selectedLabel = _categoryLabel(categories, _selectedCategoryId);

    return Scaffold(
      backgroundColor: _pageColor(context),
      appBar: AppBar(
        titleSpacing: AppSpacing.lg,
        centerTitle: false,
        title: const _ShopTitle(),
        actions: [
          IconButton(
            tooltip: 'Mở danh mục',
            icon: const Icon(Icons.grid_view_rounded),
            onPressed: () => context.push('/catalog'),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: _buildBody(
          context: context,
          state: catalogState,
          categories: categories,
          products: products,
          selectedLabel: selectedLabel,
        ),
      ),
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required CatalogState state,
    required List<Category> categories,
    required List<Product> products,
    required String selectedLabel,
  }) {
    if (state.isLoading && state.products.isEmpty) {
      return const _ShopLoadingView(key: ValueKey('shop-loading'));
    }

    if (state.errorMessage != null && state.products.isEmpty) {
      return ErrorView(
        key: const ValueKey('shop-error'),
        onRetry: () => ref
            .read(catalogControllerProvider.notifier)
            .filterByCategory(state.selectedCategoryId),
      );
    }

    if (state.products.isEmpty) {
      return const EmptyView(
        key: ValueKey('shop-empty'),
        title: 'Chưa có sản phẩm',
        description: 'Sản phẩm mới sẽ hiển thị khi danh mục được cập nhật.',
        icon: Icons.inventory_2_outlined,
      );
    }

    if (products.isEmpty) {
      return EmptyView(
        key: ValueKey('shop-empty-$_selectedCategoryId'),
        title: 'Chưa có sản phẩm trong $selectedLabel',
        description: 'Thử danh mục khác hoặc xem toàn bộ cửa hàng.',
        icon: Icons.category_outlined,
        actionText: 'Xem tất cả',
        onActionPressed: () {
          setState(() => _selectedCategoryId = null);
        },
      );
    }

    return RefreshIndicator(
      key: ValueKey('shop-content-${_selectedCategoryId ?? 'all'}'),
      onRefresh: () async {
        await ref
            .read(catalogControllerProvider.notifier)
            .filterByCategory(null);
      },
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: _ShopSummaryCard(
                selectedLabel: selectedLabel,
                productCount: products.length,
              ),
            ),
          ),
          if (_selectedCategoryId == null)
            SliverToBoxAdapter(
              child: _FeaturedProductRail(
                products: _featuredProducts(state.products),
                onProductTap: (product) =>
                    context.push('/product/${product.id}'),
              ),
            ),
          SliverToBoxAdapter(
            child: _CategoryRail(
              categories: categories,
              selectedCategoryId: _selectedCategoryId,
              totalCount: state.products.length,
              countForCategory: (id) =>
                  state.products.where((p) => p.categoryId == id).length,
              onSelected: (categoryId) {
                setState(() => _selectedCategoryId = categoryId);
              },
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            sliver: SliverToBoxAdapter(
              child: _SectionTitle(
                title: selectedLabel == 'Tất cả'
                    ? 'Tất cả sản phẩm'
                    : selectedLabel,
                subtitle: '${products.length} sản phẩm',
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 0.64,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final product = products[index];
                return ProductCard(
                  product: product,
                  onTap: () => context.push('/product/${product.id}'),
                );
              }, childCount: products.length),
            ),
          ),
        ],
      ),
    );
  }

  List<Product> _filteredProducts(List<Product> products) {
    if (_selectedCategoryId == null) return products;
    return products
        .where((product) => product.categoryId == _selectedCategoryId)
        .toList();
  }

  List<Product> _featuredProducts(List<Product> products) {
    final featured = [...products]
      ..sort((a, b) {
        final bStock = b.variants.fold<int>(
          0,
          (total, variant) => total + variant.stockQuantity,
        );
        final aStock = a.variants.fold<int>(
          0,
          (total, variant) => total + variant.stockQuantity,
        );
        final stockCompare = bStock.compareTo(aStock);
        if (stockCompare != 0) return stockCompare;
        return b.basePrice.compareTo(a.basePrice);
      });
    return featured.take(6).toList();
  }

  List<Category> _normalizedCategories(CatalogState state) {
    final categories = [...state.categories]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    if (categories.isNotEmpty) return categories;

    final ids = state.products.map((product) => product.categoryId).toSet();
    return ids
        .map((id) => Category(id: id, name: _formatCategoryName(id)))
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  String _categoryLabel(List<Category> categories, String? categoryId) {
    if (categoryId == null) return 'Tất cả';
    return categories
            .where((category) => category.id == categoryId)
            .map((category) => category.name)
            .firstOrNull ??
        _formatCategoryName(categoryId);
  }

  String _formatCategoryName(String value) {
    final cleaned = value.replaceAll('-', ' ').replaceAll('_', ' ').trim();
    if (cleaned.isEmpty) return 'Danh mục';
    return cleaned
        .split(RegExp(r'\s+'))
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  Color _pageColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
  }
}

class _ShopTitle extends StatelessWidget {
  const _ShopTitle();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cửa hàng',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          'Danh mục thương hiệu và tồn kho theo chi nhánh',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _ShopSummaryCard extends StatelessWidget {
  final String selectedLabel;
  final int productCount;

  const _ShopSummaryCard({
    required this.selectedLabel,
    required this.productCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF151C2C), Color(0xFF0B1020)]
              : const [Color(0xFFFFFFFF), Color(0xFFF1F5F9)],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.06),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isDark ? AppColors.borderDark : AppColors.primary,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: const Icon(
              Icons.auto_awesome_motion_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedLabel == 'Tất cả'
                      ? 'Danh mục nổi bật của thương hiệu'
                      : 'Bộ sưu tập $selectedLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '$productCount mẫu đang có tại các chi nhánh',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedProductRail extends StatelessWidget {
  final List<Product> products;
  final ValueChanged<Product> onProductTap;

  const _FeaturedProductRail({
    required this.products,
    required this.onProductTap,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Sản phẩm nổi bật',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Icon(Icons.trending_up_rounded, size: 20),
            ],
          ),
        ),
        SizedBox(
          height: 178,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (context, index) =>
                const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              final product = products[index];
              return _FeaturedProductCard(
                product: product,
                rank: index + 1,
                onTap: () => onProductTap(product),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FeaturedProductCard extends StatelessWidget {
  final Product product;
  final int rank;
  final VoidCallback onTap;

  const _FeaturedProductCard({
    required this.product,
    required this.rank,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final image = product.images.isNotEmpty
        ? product.images.first
        : 'https://via.placeholder.com/400x400.png?text=No+Image';
    final price = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'VND',
      decimalDigits: 0,
    ).format(product.basePrice);

    return SizedBox(
      width: 290,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    image,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const ColoredBox(color: AppColors.primary),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.10),
                          Colors.black.withValues(alpha: 0.12),
                          Colors.black.withValues(alpha: 0.70),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: AppSpacing.sm,
                    left: AppSpacing.sm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusCircular,
                        ),
                      ),
                      child: Text(
                        '#$rank Nổi bật',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: AppSpacing.md,
                    right: AppSpacing.md,
                    bottom: AppSpacing.md,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          price,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.86),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryRail extends StatelessWidget {
  final List<Category> categories;
  final String? selectedCategoryId;
  final int totalCount;
  final int Function(String id) countForCategory;
  final ValueChanged<String?> onSelected;

  const _CategoryRail({
    required this.categories,
    required this.selectedCategoryId,
    required this.totalCount,
    required this.countForCategory,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length + 1,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _CategoryChip(
              label: 'Tất cả',
              count: totalCount,
              icon: Icons.grid_view_rounded,
              selected: selectedCategoryId == null,
              onTap: () => onSelected(null),
            );
          }

          final category = categories[index - 1];
          return _CategoryChip(
            label: category.name,
            count: countForCategory(category.id),
            icon: _iconForCategory(category.id),
            selected: selectedCategoryId == category.id,
            onTap: () => onSelected(category.id),
          );
        },
      ),
    );
  }

  IconData _iconForCategory(String id) {
    final lower = id.toLowerCase();
    if (lower.contains('nike') || lower.contains('running')) {
      return Icons.directions_run_rounded;
    }
    if (lower.contains('adidas') || lower.contains('sport')) {
      return Icons.sports_soccer_rounded;
    }
    if (lower.contains('puma') || lower.contains('lifestyle')) {
      return Icons.flash_on_rounded;
    }
    if (lower.contains('dep') || lower.contains('slide')) {
      return Icons.waves_rounded;
    }
    return Icons.category_rounded;
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.count,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: selected
          ? (isDark ? Colors.white : AppColors.primary)
          : (isDark ? AppColors.surfaceDark : Colors.white),
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          constraints: const BoxConstraints(minWidth: 82, minHeight: 44),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : (isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected
                    ? (isDark ? AppColors.primary : Colors.white)
                    : (isDark ? Colors.white : AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.xs),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 96),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: selected
                        ? (isDark ? AppColors.primary : Colors.white)
                        : null,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: selected
                      ? (isDark
                            ? AppColors.primary.withValues(alpha: 0.10)
                            : Colors.white.withValues(alpha: 0.16))
                      : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(
                    AppSpacing.radiusCircular,
                  ),
                ),
                child: Text(
                  '$count',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: selected
                        ? (isDark ? AppColors.primary : Colors.white)
                        : AppColors.primary,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(subtitle, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _ShopLoadingView extends StatelessWidget {
  const _ShopLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          sliver: SliverToBoxAdapter(
            child: Container(
              height: 84,
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 64,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              separatorBuilder: (context, index) =>
                  const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) => Container(
                width: 104,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                  ),
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              childAspectRatio: 0.64,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => const ProductCardSkeleton(),
              childCount: 6,
            ),
          ),
        ),
      ],
    );
  }
}
