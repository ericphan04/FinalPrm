import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../providers/commerce_providers.dart';
import '../widgets/product_card.dart';
import '../../../../../core/widgets/product_card_skeleton.dart';
import '../../../../../core/widgets/error_view.dart';
import '../../../../../core/widgets/empty_view.dart';

class ShopTab extends ConsumerStatefulWidget {
  const ShopTab({super.key});

  @override
  ConsumerState<ShopTab> createState() => _ShopTabState();
}

class _ShopTabState extends ConsumerState<ShopTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Shop',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: isDark ? Colors.white : Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: isDark ? Colors.white : Colors.black,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          tabs: const [
            Tab(text: 'Men'),
            Tab(text: 'Women'),
            Tab(text: 'Kids'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildShopContent(context, ref, 'Men'),
          _buildShopContent(context, ref, 'Women'),
          _buildShopContent(context, ref, 'Kids'),
        ],
      ),
    );
  }

  Widget _buildShopContent(
    BuildContext context,
    WidgetRef ref,
    String categoryName,
  ) {
    final catalogState = ref.watch(catalogControllerProvider);

    if (catalogState.isLoading && catalogState.products.isEmpty) {
      return const Center(child: CircularProgressIndicator());
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
        title: 'No products found',
        description: 'Check back later for new arrivals.',
        icon: Icons.inventory_2_outlined,
      );
    }

    // Tạm thời chia đôi danh sách sản phẩm cho 2 mục
    final products = catalogState.products;
    final mid = (products.length / 2).ceil();
    final newArrivals = products.take(mid).toList();
    final highlights = products.skip(mid).toList();

    return ListView(
      padding: const EdgeInsets.only(
        top: AppSpacing.lg,
        bottom: 120,
      ), // Padding cho floating nav bar
      children: [
        _buildSection(context, 'New Arrivals', newArrivals),
        const SizedBox(height: AppSpacing.xl),
        _buildSection(
          context,
          "This Week's Highlights",
          highlights.isEmpty ? newArrivals : highlights,
        ),
      ],
    );
  }

  Widget _buildSection(BuildContext context, String title, List products) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height:
              320, // Chiều cao cố định cho horizontal list của product cards
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (context, index) =>
                const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              final product = products[index];
              return SizedBox(
                width: 200, // Chiều rộng cố định cho mỗi card để cuộn ngang
                child: ProductCard(
                  product: product,
                  onTap: () => context.push('/product/${product.id}'),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
