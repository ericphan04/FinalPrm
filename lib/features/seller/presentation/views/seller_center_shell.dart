import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../commerce/domain/models/product.dart';
import '../controllers/seller_stats_controller.dart';
import '../providers/seller_providers.dart';

class SellerCenterShell extends ConsumerStatefulWidget {
  const SellerCenterShell({super.key});

  @override
  ConsumerState<SellerCenterShell> createState() => _SellerCenterShellState();
}

class _SellerCenterShellState extends ConsumerState<SellerCenterShell> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tabs = [const _OverviewTab(), const _InventoryTab()];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bảng điều khiển chi nhánh'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Quay lại',
          onPressed: () => context.go('/seller/dashboard'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới',
            onPressed: () {
              ref.invalidate(sellerStatsControllerProvider);
              ref.read(sellerProductControllerProvider.notifier).loadProducts();
            },
          ),
        ],
      ),
      body: IndexedStack(index: _currentTab, children: tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (idx) => setState(() => _currentTab = idx),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: isDark ? Colors.white54 : Colors.black54,
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard_rounded),
            label: 'Tổng quan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2_rounded),
            label: 'Kho hàng',
          ),
        ],
      ),
    );
  }
}

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(sellerStatsControllerProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Lỗi: $err')),
      data: (stats) {
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(sellerStatsControllerProvider);
            await ref
                .read(sellerProductControllerProvider.notifier)
                .loadProducts();
          },
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(
                'Vận hành chi nhánh',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Theo dõi tồn kho và gửi yêu cầu bổ sung hàng cho admin.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.textDarkMuted
                      : AppColors.textLightMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Sản phẩm trong kho',
                      value: '${stats.totalProducts}',
                      icon: Icons.inventory_2_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _StatCard(
                      title: 'Doanh thu ghi nhận',
                      value: currencyFormatter.format(stats.totalRevenue),
                      icon: Icons.payments_outlined,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              if (stats.lowStockProductsCount > 0)
                _LowStockPanel(stats: stats)
              else
                const _HealthyStockPanel(),
            ],
          ),
        );
      },
    );
  }
}

class _LowStockPanel extends StatelessWidget {
  final SellerStats stats;

  const _LowStockPanel({required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.error,
                size: 28,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Có ${stats.lowStockProductsCount} sản phẩm sắp hết hàng. Gửi yêu cầu nhập thêm để quản trị xử lý.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Sản phẩm cần bổ sung',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final product in stats.lowStockProducts) ...[
          Builder(
            builder: (context) {
              final stocks = product.variants
                  .map((variant) => variant.stockQuantity)
                  .toList();
              final minStock = stocks.isEmpty
                  ? 0
                  : stocks.reduce((a, b) => a < b ? a : b);
              return Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: ListTile(
                  leading: _ProductThumb(product: product, size: 50),
                  title: Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    'Tồn kho thấp nhất: $minStock đôi',
                    style: const TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.add_business_rounded,
                    color: AppColors.primary,
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}

class _HealthyStockPanel extends StatelessWidget {
  const _HealthyStockPanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            color: AppColors.success,
            size: 48,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Kho hàng ổn định',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Các sản phẩm trong chi nhánh đang có tồn kho phù hợp.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      constraints: const BoxConstraints(minHeight: 132),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 28),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark
                  ? AppColors.textDarkMuted
                  : AppColors.textLightMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryTab extends ConsumerWidget {
  const _InventoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sellerProductControllerProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.products.isEmpty) {
      return const EmptyView(
        title: 'Chưa có hàng trong chi nhánh',
        description:
            'Quản trị sẽ phân bổ hàng hóa thương hiệu về chi nhánh này.',
        icon: Icons.inventory_2_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(sellerProductControllerProvider.notifier).loadProducts();
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: state.products.length,
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          final product = state.products[index];
          final totalStock = product.variants.fold<int>(
            0,
            (total, variant) => total + variant.stockQuantity,
          );
          final lowStock = totalStock < 5;

          return Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProductThumb(product: product, size: 76),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(currencyFormatter.format(product.basePrice)),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.xs,
                            runSpacing: AppSpacing.xs,
                            children: [
                              _InventoryBadge(
                                label: 'Kho: $totalStock',
                                color: lowStock
                                    ? AppColors.error
                                    : AppColors.success,
                              ),
                              _InventoryBadge(
                                label: product.status.nameVi,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  text: lowStock
                      ? 'Báo admin nhập thêm hàng'
                      : 'Yêu cầu bổ sung hàng',
                  icon: const Icon(Icons.add_business_rounded, size: 18),
                  variant: lowStock
                      ? AppButtonVariant.primary
                      : AppButtonVariant.secondary,
                  width: double.infinity,
                  onPressed: () =>
                      _showStockRequestDialog(context, ref, product),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showStockRequestDialog(
    BuildContext context,
    WidgetRef ref,
    Product product,
  ) {
    final quantityController = TextEditingController(text: '10');
    final noteController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Yêu cầu nhập hàng'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(product.name),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: quantityController,
                labelText: 'Số lượng cần bổ sung',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: noteController,
                labelText: 'Ghi chú cho admin',
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            AppButton(
              text: 'Gửi yêu cầu',
              onPressed: () async {
                final quantity =
                    int.tryParse(quantityController.text.trim()) ?? 0;
                final ok = await ref
                    .read(sellerProductControllerProvider.notifier)
                    .requestStockReplenishment(
                      product,
                      requestedQuantity: quantity,
                      note: noteController.text.trim(),
                    );
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        ok
                            ? 'Đã gửi yêu cầu nhập hàng cho admin'
                            : 'Không thể gửi yêu cầu nhập hàng',
                      ),
                      backgroundColor: ok ? AppColors.success : AppColors.error,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}

class _ProductThumb extends StatelessWidget {
  final Product product;
  final double size;

  const _ProductThumb({required this.product, required this.size});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Container(
        width: size,
        height: size,
        color: isDark ? AppColors.borderDark : AppColors.primaryLight,
        child: product.images.isNotEmpty
            ? Image.network(product.images.first, fit: BoxFit.cover)
            : const Icon(Icons.image_outlined),
      ),
    );
  }
}

class _InventoryBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _InventoryBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
