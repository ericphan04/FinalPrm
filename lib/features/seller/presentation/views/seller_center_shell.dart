import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../commerce/domain/models/product.dart';
import '../../../commerce/domain/models/app_order.dart';
import '../providers/seller_providers.dart';
import '../controllers/seller_product_controller.dart';
import '../controllers/seller_order_controller.dart';
import '../controllers/store_profile_controller.dart';
import '../controllers/seller_stats_controller.dart';
import 'seller_product_form_view.dart';
import 'seller_order_detail_view.dart';

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

    final tabs = [
      const _OverviewTab(),
      const _ProductsTab(),
      const _OrdersTab(),
      const _ProfileTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kênh Người Bán'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới',
            onPressed: () {
              ref.invalidate(sellerStatsControllerProvider);
              ref.read(sellerProductControllerProvider.notifier).loadProducts();
              ref.read(sellerOrderControllerProvider.notifier).loadOrders();
              ref.read(storeProfileControllerProvider.notifier).loadProfile();
            },
          ),
          IconButton(
            icon: const Icon(Icons.home_rounded),
            tooltip: 'Trang chủ',
            onPressed: () => context.go('/'),
          ),
        ],
      ),
      body: IndexedStack(index: _currentTab, children: tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (idx) {
          setState(() {
            _currentTab = idx;
          });
        },
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
            icon: Icon(Icons.shopping_bag_outlined),
            activeIcon: Icon(Icons.shopping_bag_rounded),
            label: 'Sản phẩm',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long_rounded),
            label: 'Đơn hàng',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined),
            activeIcon: Icon(Icons.storefront_rounded),
            label: 'Cửa hàng',
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
      symbol: '₫',
      decimalDigits: 0,
    );

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Lỗi: $err')),
      data: (stats) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hiệu quả bán hàng',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Stats Grid
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Tổng sản phẩm',
                      '${stats.totalProducts}',
                      Icons.inventory_2_outlined,
                      AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Doanh thu',
                      currencyFormatter.format(stats.totalRevenue),
                      Icons.monetization_on_outlined,
                      AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Low Stock Alert Banner / Card
              if (stats.lowStockProductsCount > 0) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cảnh báo tồn kho thấp',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.error,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Có ${stats.lowStockProductsCount} sản phẩm gần hết hàng (số lượng < 5). Hãy bổ sung tồn kho ngay.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? Colors.red[100]
                                    : Colors.red[900],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                Text(
                  'Danh sách hết hàng/tồn kho thấp',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: stats.lowStockProducts.length,
                  itemBuilder: (context, index) {
                    final product = stats.lowStockProducts[index];
                    final minStock = product.variants
                        .map((e) => e.stockQuantity)
                        .reduce((a, b) => a < b ? a : b);
                    return Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 50,
                            height: 50,
                            color: Colors.grey[300],
                            child: product.images.isNotEmpty
                                ? Image.network(
                                    product.images.first,
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(Icons.image, color: Colors.grey),
                          ),
                        ),
                        title: Text(
                          product.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Tồn kho nhỏ nhất: $minStock đôi',
                          style: const TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.edit_note_rounded,
                            color: AppColors.primary,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    SellerProductFormView(product: product),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ] else ...[
                // Success / Empty alert
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.success.withOpacity(0.2),
                    ),
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
                        'Kho hàng an toàn',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      const Text(
                        'Tất cả biến thể sản phẩm của bạn đều có tồn kho đầy đủ.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
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
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: AppSpacing.md),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            title,
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

class _ProductsTab extends ConsumerWidget {
  const _ProductsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sellerProductControllerProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SellerProductFormView()),
          );
        },
        label: const Text('Thêm sản phẩm'),
        icon: const Icon(Icons.add),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          // Filter Chips for Statuses
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                _buildFilterChip(context, ref, 'Tất cả', null),
                const SizedBox(width: AppSpacing.xs),
                _buildFilterChip(context, ref, 'Nháp', ProductStatus.draft),
                const SizedBox(width: AppSpacing.xs),
                _buildFilterChip(
                  context,
                  ref,
                  'Chờ duyệt',
                  ProductStatus.pendingReview,
                ),
                const SizedBox(width: AppSpacing.xs),
                _buildFilterChip(
                  context,
                  ref,
                  'Đang bán',
                  ProductStatus.published,
                ),
                const SizedBox(width: AppSpacing.xs),
                _buildFilterChip(
                  context,
                  ref,
                  'Bị từ chối',
                  ProductStatus.rejected,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Product List
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.products.isEmpty
                ? const EmptyView(
                    title: 'Chưa có sản phẩm nào',
                    description: 'Nhấn nút Thêm sản phẩm để bắt đầu đăng bán hàng.',
                  )
                : ListView.builder(
                    itemCount: state.products.length,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemBuilder: (context, index) {
                      final product = state.products[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Image
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      width: 80,
                                      height: 80,
                                      color: Colors.grey[200],
                                      child: product.images.isNotEmpty
                                          ? Image.network(
                                              product.images.first,
                                              fit: BoxFit.cover,
                                            )
                                          : const Icon(
                                              Icons.image,
                                              size: 36,
                                              color: Colors.grey,
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  // Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product.name,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: AppSpacing.xs),
                                        Text(
                                          currencyFormatter.format(
                                            product.basePrice,
                                          ),
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                        ),
                                        const SizedBox(height: AppSpacing.sm),
                                        _buildStatusBadge(product.status),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              // Rejection Reason
                              if (product.status == ProductStatus.rejected &&
                                  product.rejectReason != null) ...[
                                const SizedBox(height: AppSpacing.md),
                                Container(
                                  padding: const EdgeInsets.all(AppSpacing.sm),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  width: double.infinity,
                                  child: Text(
                                    'Lý do từ chối: ${product.rejectReason}',
                                    style: const TextStyle(
                                      color: AppColors.error,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],

                              const SizedBox(height: AppSpacing.md),
                              const Divider(height: 1),
                              const SizedBox(height: AppSpacing.sm),

                              // Action Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  // Delete draft button
                                  if (product.status ==
                                      ProductStatus.draft) ...[
                                    TextButton.icon(
                                      onPressed: () {
                                        ref
                                            .read(
                                              sellerProductControllerProvider
                                                  .notifier,
                                            )
                                            .deleteProductDraft(product.id)
                                            .then((ok) {
                                              if (ok) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Đã xóa sản phẩm nháp',
                                                    ),
                                                  ),
                                                );
                                              }
                                            });
                                      },
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: AppColors.error,
                                      ),
                                      label: const Text(
                                        'Xóa',
                                        style: TextStyle(
                                          color: AppColors.error,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                  ],

                                  // Edit button
                                  if (product.status == ProductStatus.draft ||
                                      product.status ==
                                          ProductStatus.rejected) ...[
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                SellerProductFormView(
                                                  product: product,
                                                ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.edit_rounded,
                                        size: 16,
                                      ),
                                      label: const Text('Sửa'),
                                      style: OutlinedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),

                                    // Submit for review
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        ref
                                            .read(
                                              sellerProductControllerProvider
                                                  .notifier,
                                            )
                                            .submitProductForReview(product.id)
                                            .then((ok) {
                                              if (ok) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Đã gửi duyệt sản phẩm!',
                                                    ),
                                                  ),
                                                );
                                              }
                                            });
                                      },
                                      icon: const Icon(
                                        Icons.publish_rounded,
                                        size: 16,
                                      ),
                                      label: const Text('Gửi duyệt'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ] else ...[
                                    Text(
                                      product.status ==
                                              ProductStatus.pendingReview
                                          ? 'Đang chờ Admin phê duyệt'
                                          : 'Sản phẩm đang được bán',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? AppColors.textDarkMuted
                                            : AppColors.textLightMuted,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    WidgetRef ref,
    String label,
    ProductStatus? status,
  ) {
    final currentFilter = ref
        .watch(sellerProductControllerProvider)
        .filterStatus;
    final isSelected = currentFilter == status;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          ref
              .read(sellerProductControllerProvider.notifier)
              .setFilterStatus(status);
        }
      },
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected
            ? Colors.white
            : (Theme.of(context).brightness == Brightness.dark
                ? Colors.white70
                : Colors.black87),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildStatusBadge(ProductStatus status) {
    Color color;
    String label = status.nameVi;
    switch (status) {
      case ProductStatus.draft:
        color = Colors.grey;
        break;
      case ProductStatus.pendingReview:
        color = Colors.orange;
        break;
      case ProductStatus.published:
        color = AppColors.success;
        break;
      case ProductStatus.rejected:
        color = AppColors.error;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
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

class _OrdersTab extends ConsumerWidget {
  const _OrdersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sellerOrderControllerProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

    return Column(
      children: [
        // Dropdown status filter
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: DropdownButtonFormField<OrderStatus?>(
            value: state.filterStatus,
            decoration: InputDecoration(
              labelText: 'Lọc theo trạng thái',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
            ),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('Tất cả đơn hàng'),
              ),
              ...OrderStatus.values.map(
                (status) => DropdownMenuItem(
                  value: status,
                  child: Text(_getOrderStatusNameVi(status)),
                ),
              ),
            ],
            onChanged: (val) {
              ref
                  .read(sellerOrderControllerProvider.notifier)
                  .setFilterStatus(val);
            },
          ),
        ),
        const Divider(height: 1),

        // List
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ref
                    .watch(sellerOrderControllerProvider.notifier)
                    .filteredOrders
                    .isEmpty
              ? const EmptyView(
                  title: 'Chưa có đơn hàng nào',
                  description:
                      'Các đơn hàng liên quan đến sản phẩm của bạn sẽ hiển thị tại đây.',
                )
              : ListView.builder(
                  itemCount: ref
                      .watch(sellerOrderControllerProvider.notifier)
                      .filteredOrders
                      .length,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemBuilder: (context, index) {
                    final order = ref
                        .watch(sellerOrderControllerProvider.notifier)
                        .filteredOrders[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(AppSpacing.md),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Đơn hàng: #${order.id.substring(0, 8).toUpperCase()}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            _buildOrderStatusBadge(order.status),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Ngày tạo: ${DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt)}',
                            ),
                            Text(
                              'Tổng tiền: ${currencyFormatter.format(order.totalAmount)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            Text(
                              'Khách hàng: ${order.shippingAddress.fullName}',
                            ),
                          ],
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  SellerOrderDetailView(order: order),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  String _getOrderStatusNameVi(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Chờ xác nhận';
      case OrderStatus.confirmed:
        return 'Đã xác nhận';
      case OrderStatus.shipping:
        return 'Đang giao';
      case OrderStatus.completed:
        return 'Hoàn thành';
      case OrderStatus.cancelled:
        return 'Đã hủy';
    }
  }

  Widget _buildOrderStatusBadge(OrderStatus status) {
    Color color;
    String label = _getOrderStatusNameVi(status);
    switch (status) {
      case OrderStatus.pending:
        color = Colors.orange;
        break;
      case OrderStatus.confirmed:
        color = Colors.blue;
        break;
      case OrderStatus.shipping:
        color = Colors.purple;
        break;
      case OrderStatus.completed:
        color = AppColors.success;
        break;
      case OrderStatus.cancelled:
        color = AppColors.error;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
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

class _ProfileTab extends ConsumerStatefulWidget {
  const _ProfileTab();

  @override
  ConsumerState<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<_ProfileTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isInitialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _descController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      ref
          .read(storeProfileControllerProvider.notifier)
          .updateProfile(
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            description: _descController.text.trim(),
            address: _addressController.text.trim(),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storeProfileControllerProvider);

    if (state.profile != null && !_isInitialized) {
      _nameController.text = state.profile!.name;
      _phoneController.text = state.profile!.phone;
      _descController.text = state.profile!.description;
      _addressController.text = state.profile!.address;
      _isInitialized = true;
    }

    ref.listen(storeProfileControllerProvider, (previous, next) {
      if (next.isSaveSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lưu thông tin cửa hàng thành công!'),
            backgroundColor: AppColors.success,
          ),
        );
        ref.read(storeProfileControllerProvider.notifier).clearStatus();
      }
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
        ref.read(storeProfileControllerProvider.notifier).clearStatus();
      }
    });

    return state.isLoading && state.profile == null
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: const Icon(
                            Icons.store_rounded,
                            size: 50,
                            color: AppColors.primary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  AppTextField(
                    controller: _nameController,
                    labelText: 'Tên shop',
                    prefixIcon: const Icon(
                      Icons.store_rounded,
                      color: AppColors.primary,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Tên shop không được để trống';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  AppTextField(
                    controller: _phoneController,
                    labelText: 'Số điện thoại',
                    keyboardType: TextInputType.phone,
                    prefixIcon: const Icon(
                      Icons.phone_rounded,
                      color: AppColors.primary,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Số điện thoại không được để trống';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  AppTextField(
                    controller: _descController,
                    labelText: 'Mô tả shop',
                    maxLines: 3,
                    prefixIcon: const Icon(
                      Icons.description,
                      color: AppColors.primary,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Mô tả shop không được để trống';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  AppTextField(
                    controller: _addressController,
                    labelText: 'Địa chỉ lấy hàng',
                    prefixIcon: const Icon(
                      Icons.location_on_rounded,
                      color: AppColors.primary,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Địa chỉ lấy hàng không được để trống';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      text: 'Cập nhật cửa hàng',
                      onPressed: _saveProfile,
                      variant: AppButtonVariant.primary,
                    ),
                  ),
                ],
              ),
            ),
          );
  }
}
