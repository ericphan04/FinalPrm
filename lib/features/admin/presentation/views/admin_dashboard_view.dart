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
import '../../../auth/domain/models/app_user_role.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/admin_providers.dart';

import '../../../auth/domain/models/app_user.dart';
import '../../../commerce/domain/models/app_order.dart';
import '../../../commerce/domain/models/product.dart';
import '../../../seller/domain/models/seller_application.dart';

class AdminDashboardView extends ConsumerStatefulWidget {
  const AdminDashboardView({super.key});

  @override
  ConsumerState<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends ConsumerState<AdminDashboardView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  // System config fields
  final _lowStockController = TextEditingController();
  final _cancelHoursController = TextEditingController();
  bool _isSavingConfig = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _lowStockController.dispose();
    _cancelHoursController.dispose();
    super.dispose();
  }

  void _showRejectDialog({
    required String title,
    required String labelText,
    required Function(String reason) onConfirm,
  }) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: AppTextField(
          controller: reasonController,
          labelText: labelText,
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          AppButton(
            text: 'Xác nhận từ chối',
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
                Navigator.pop(ctx);
                onConfirm(reasonController.text.trim());
              }
            },
            variant: AppButtonVariant.primary,
          ),
        ],
      ),
    );
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
          'Hệ Thống Quản Trị (Admin)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Đăng xuất',
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).signOut();
              if (context.mounted) context.go('/');
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_rounded), text: 'Tổng quan'),
            Tab(icon: Icon(Icons.people_alt_rounded), text: 'Duyệt Seller'),
            Tab(icon: Icon(Icons.shopping_bag_rounded), text: 'Duyệt Sản phẩm'),
            Tab(icon: Icon(Icons.person_rounded), text: 'Người dùng'),
            Tab(icon: Icon(Icons.receipt_long_rounded), text: 'Đơn hàng'),
            Tab(icon: Icon(Icons.list_alt_rounded), text: 'Audit Logs'),
            Tab(icon: Icon(Icons.settings_rounded), text: 'Cấu hình'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildSellerApprovalTab(),
          _buildProductModerationTab(),
          _buildUsersTab(),
          _buildOrdersTab(),
          _buildAuditLogsTab(),
          _buildConfigTab(),
        ],
      ),
    );
  }

  // 1. OVERVIEW TAB
  Widget _buildOverviewTab() {
    final usersAsync = ref.watch(allUsersProvider);
    final ordersAsync = ref.watch(allOrdersProvider);
    final productsAsync = ref.watch(pendingProductsProvider);

    return usersAsync.when(
      loading: () => const LoadingView(),
      error: (err, stack) => ErrorView(
        message: err.toString(),
        onRetry: () => ref.refresh(allUsersProvider),
      ),
      data: (users) {
        return ordersAsync.when(
          loading: () => const LoadingView(),
          error: (err, stack) => ErrorView(
            message: err.toString(),
            onRetry: () => ref.refresh(allOrdersProvider),
          ),
          data: (orders) {
            final sellerCount = users
                .where((u) => u.role == AppUserRole.seller)
                .length;
            final userCount = users
                .where((u) => u.role == AppUserRole.user)
                .length;
            final totalRevenue = orders
                .where((o) => o.status == OrderStatus.completed)
                .fold<double>(0, (sum, o) => sum + o.totalAmount);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Số liệu tổng hợp vận hành',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                    childAspectRatio: 1.2,
                    children: [
                      _buildStatCard(
                        title: 'Doanh thu hoàn thành',
                        value: _currencyFormat.format(totalRevenue),
                        icon: Icons.monetization_on_rounded,
                        color: Colors.green,
                      ),
                      _buildStatCard(
                        title: 'Tổng số đơn hàng',
                        value: '${orders.length}',
                        icon: Icons.receipt_rounded,
                        color: Colors.blue,
                      ),
                      _buildStatCard(
                        title: 'Người bán (Sellers)',
                        value: '$sellerCount',
                        icon: Icons.storefront_rounded,
                        color: Colors.purple,
                      ),
                      _buildStatCard(
                        title: 'Khách hàng (Users)',
                        value: '$userCount',
                        icon: Icons.people_rounded,
                        color: Colors.orange,
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      color: isDark ? AppColors.surfaceDark : Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: AppSpacing.xxs),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 2. SELLER APPROVAL TAB
  Widget _buildSellerApprovalTab() {
    final pendingAppsAsync = ref.watch(pendingSellerApplicationsProvider);
    return pendingAppsAsync.when(
      loading: () => const LoadingView(),
      error: (err, stack) => ErrorView(
        message: err.toString(),
        onRetry: () => ref.refresh(pendingSellerApplicationsProvider),
      ),
      data: (apps) {
        final pendingApps =
            apps.where((a) => a.status == SellerApplicationStatus.pending).toList();
        if (pendingApps.isEmpty) {
          return const EmptyView(
            title: 'Hồ sơ trống',
            description:
                'Hiện không có đơn ứng tuyển người bán nào đang chờ duyệt.',
            icon: Icons.person_search_rounded,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: pendingApps.length,
          itemBuilder: (context, index) {
            final app = pendingApps[index];
            return Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.storeName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text('SĐT: ${app.phone}'),
                    Text('Mô tả: ${app.description}'),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AppButton(
                          text: 'Từ chối',
                          onPressed: () {
                            _showRejectDialog(
                              title: 'Từ chối hồ sơ người bán',
                              labelText: 'Lý do từ chối',
                              onConfirm: (reason) async {
                                final repo = ref.read(adminRepositoryProvider);
                                final res = await repo.reviewSellerApplication(
                                  app.id,
                                  'reject',
                                  reason: reason,
                                );
                                res.when(
                                  onSuccess: (_) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Đã từ chối đơn ứng tuyển',
                                        ),
                                      ),
                                    );
                                    ref.refresh(
                                      pendingSellerApplicationsProvider,
                                    );
                                  },
                                  onFailure: (fail) =>
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('Lỗi: ${fail.message}'),
                                        ),
                                      ),
                                );
                              },
                            );
                          },
                          variant: AppButtonVariant.outlined,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        AppButton(
                          text: 'Duyệt',
                          onPressed: () async {
                            final repo = ref.read(adminRepositoryProvider);
                            final res = await repo.reviewSellerApplication(
                              app.id,
                              'approve',
                            );
                            res.when(
                              onSuccess: (_) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Đã phê duyệt người bán thành công!',
                                    ),
                                  ),
                                );
                                ref.refresh(pendingSellerApplicationsProvider);
                                ref.refresh(allUsersProvider);
                              },
                              onFailure: (fail) =>
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Lỗi: ${fail.message}'),
                                    ),
                                  ),
                            );
                          },
                          variant: AppButtonVariant.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 3. PRODUCT MODERATION TAB
  Widget _buildProductModerationTab() {
    final pendingProductsAsync = ref.watch(pendingProductsProvider);
    return pendingProductsAsync.when(
      loading: () => const LoadingView(),
      error: (err, stack) =>
          ErrorView(onRetry: () => ref.refresh(pendingProductsProvider)),
      data: (products) {
        if (products.isEmpty) {
          return const EmptyView(
            title: 'Không có sản phẩm',
            description: 'Hiện không có sản phẩm nào đang chờ kiểm duyệt.',
            icon: Icons.inventory_2_outlined,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final prod = products[index];
            return Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prod.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Giá cơ bản: ${_currencyFormat.format(prod.basePrice)}',
                    ),
                    Text('Mô tả: ${prod.description}'),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AppButton(
                          text: 'Từ chối',
                          onPressed: () {
                            _showRejectDialog(
                              title: 'Từ chối sản phẩm',
                              labelText: 'Lý do từ chối sản phẩm',
                              onConfirm: (reason) async {
                                final repo = ref.read(adminRepositoryProvider);
                                final res = await repo.reviewProduct(
                                  prod.id,
                                  'reject',
                                  reason: reason,
                                );
                                res.when(
                                  onSuccess: (_) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Đã từ chối sản phẩm'),
                                      ),
                                    );
                                    ref.refresh(pendingProductsProvider);
                                  },
                                  onFailure: (fail) =>
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('Lỗi: ${fail.message}'),
                                        ),
                                      ),
                                );
                              },
                            );
                          },
                          variant: AppButtonVariant.outlined,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        AppButton(
                          text: 'Duyệt & Đăng',
                          onPressed: () async {
                            final repo = ref.read(adminRepositoryProvider);
                            final res = await repo.reviewProduct(
                              prod.id,
                              'approve',
                            );
                            res.when(
                              onSuccess: (_) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Đã duyệt đăng sản phẩm!'),
                                  ),
                                );
                                ref.refresh(pendingProductsProvider);
                              },
                              onFailure: (fail) =>
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Lỗi: ${fail.message}'),
                                    ),
                                  ),
                            );
                          },
                          variant: AppButtonVariant.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 4. USERS TAB
  Widget _buildUsersTab() {
    final usersAsync = ref.watch(allUsersProvider);
    return usersAsync.when(
      loading: () => const LoadingView(),
      error: (err, stack) =>
          ErrorView(onRetry: () => ref.refresh(allUsersProvider)),
      data: (users) {
        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final u = users[index];
            // dynamic cast handles null values in older instances cached during hot reloads
            final statusStr = (u.status as dynamic) ?? 'active';
            final isBlocked = statusStr == 'blocked' || statusStr == 'locked';
            return Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isBlocked
                      ? Colors.red.shade50
                      : AppColors.primary.withOpacity(0.1),
                  foregroundColor:
                      isBlocked ? Colors.red.shade700 : AppColors.primary,
                  child: Text(
                    u.displayName.isNotEmpty
                        ? u.displayName[0].toUpperCase()
                        : 'U',
                  ),
                ),
                title: Text(
                  u.displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    decoration: isBlocked ? TextDecoration.lineThrough : null,
                    color: isBlocked ? Colors.grey : null,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${u.email} | Vai trò: ${u.role.nameVi}'),
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isBlocked
                            ? Colors.red.shade50
                            : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isBlocked
                              ? Colors.red.shade200
                              : Colors.green.shade200,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        isBlocked ? 'Đã khóa' : 'Hoạt động',
                        style: TextStyle(
                          color: isBlocked
                              ? Colors.red.shade700
                              : Colors.green.shade700,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                trailing: isBlocked
                    ? IconButton(
                        icon: const Icon(
                          Icons.check_circle_outline,
                          color: Colors.green,
                          size: 26,
                        ),
                        tooltip: 'Mở khóa',
                        onPressed: () async {
                          final repo = ref.read(adminRepositoryProvider);
                          final res = await repo.updateUserStatus(
                            u.uid,
                            'active',
                          );
                          res.when(
                            onSuccess: (_) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Đã kích hoạt tài khoản thành công',
                                  ),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                              ref.refresh(allUsersProvider);
                            },
                            onFailure: (fail) =>
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Lỗi: ${fail.message}'),
                                    backgroundColor: AppColors.error,
                                  ),
                                ),
                          );
                        },
                      )
                    : IconButton(
                        icon: const Icon(
                          Icons.block_flipped,
                          color: Colors.red,
                          size: 26,
                        ),
                        tooltip: 'Khóa tài khoản',
                        onPressed: () async {
                          final repo = ref.read(adminRepositoryProvider);
                          final res = await repo.updateUserStatus(
                            u.uid,
                            'blocked',
                          );
                          res.when(
                            onSuccess: (_) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Đã khóa tài khoản thành công'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                              ref.refresh(allUsersProvider);
                            },
                            onFailure: (fail) =>
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Lỗi: ${fail.message}'),
                                    backgroundColor: AppColors.error,
                                  ),
                                ),
                          );
                        },
                      ),
              ),
            );
          },
        );
      },
    );
  }

  // 5. ORDERS TAB
  Widget _buildOrdersTab() {
    final ordersAsync = ref.watch(allOrdersProvider);
    return ordersAsync.when(
      loading: () => const LoadingView(),
      error: (err, stack) =>
          ErrorView(onRetry: () => ref.refresh(allOrdersProvider)),
      data: (orders) {
        if (orders.isEmpty) {
          return const EmptyView(
            title: 'Chưa có đơn hàng nào',
            description: 'Hệ thống chưa ghi nhận đơn đặt hàng nào.',
            icon: Icons.receipt_long_outlined,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ListTile(
                title: Text('Đơn hàng: ${order.id}'),
                subtitle: Text(
                  'Tổng: ${_currencyFormat.format(order.totalAmount)} | Trạng thái: ${order.status.name}',
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Direct detail view
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text('Chi tiết đơn: ${order.id}'),
                      content: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Khách hàng ID: ${order.userId}'),
                            Text('Trạng thái: ${order.status.name}'),
                            Text(
                              'Tổng tiền: ${_currencyFormat.format(order.totalAmount)}',
                            ),
                            Text(
                              'Phương thức thanh toán: ${order.paymentMethod}',
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            const Text(
                              'Địa chỉ nhận hàng:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text('Họ tên: ${order.shippingAddress.fullName}'),
                            Text('SĐT: ${order.shippingAddress.phone}'),
                            Text(
                              'Địa chỉ: ${order.shippingAddress.addressLine}, ${order.shippingAddress.city}',
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            const Text(
                              'Mặt hàng:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            ...order.items.map(
                              (e) => Text(
                                '- ${e.productName} (x${e.quantity}) - ${_currencyFormat.format(e.price)}',
                              ),
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Đóng'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  // 6. AUDIT LOGS TAB
  Widget _buildAuditLogsTab() {
    final logsAsync = ref.watch(auditLogsProvider);
    return logsAsync.when(
      loading: () => const LoadingView(),
      error: (err, stack) => ErrorView(
        message: err.toString(),
        onRetry: () => ref.refresh(auditLogsProvider),
      ),
      data: (logs) {
        if (logs.isEmpty) {
          return const EmptyView(
            title: 'Trống',
            description: 'Chưa có nhật ký hoạt động hệ thống nào.',
            icon: Icons.list_alt_rounded,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index];
            final timeStr = DateFormat(
              'dd/MM/yyyy HH:mm:ss',
            ).format(log.createdAt);
            return Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ListTile(
                title: Text('${log.action} - ${log.targetType}'),
                subtitle: Text(
                  'Tác nhân: ${log.actorUid} (${log.actorRole})\nLý do: ${log.reason ?? "Không có"}\nThời gian: $timeStr',
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }

  // 7. SYSTEM CONFIG CONFIG TAB
  Widget _buildConfigTab() {
    final configAsync = ref.watch(systemConfigProvider);
    return configAsync.when(
      loading: () => const LoadingView(),
      error: (err, stack) => ErrorView(
        message: err.toString(),
        onRetry: () => ref.refresh(systemConfigProvider),
      ),
      data: (config) {
        if (_lowStockController.text.isEmpty) {
          _lowStockController.text = '${config['lowStockThreshold'] ?? 5}';
          _cancelHoursController.text = '${config['cancellationHours'] ?? 24}';
        }
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cấu hình hệ thống vận hành',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                controller: _lowStockController,
                labelText: 'Ngưỡng cảnh báo tồn kho thấp',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _cancelHoursController,
                labelText: 'Thời gian tối đa để tự động hủy đơn (Giờ)',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                text: 'Lưu cấu hình',
                isLoading: _isSavingConfig,
                onPressed: () async {
                  setState(() => _isSavingConfig = true);
                  final repo = ref.read(adminRepositoryProvider);
                  final res = await repo.updateSystemConfig({
                    'lowStockThreshold':
                        int.tryParse(_lowStockController.text) ?? 5,
                    'cancellationHours':
                        int.tryParse(_cancelHoursController.text) ?? 24,
                  });
                  setState(() => _isSavingConfig = false);
                  res.when(
                    onSuccess: (_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Lưu cấu hình hệ thống thành công!'),
                        ),
                      );
                      ref.refresh(systemConfigProvider);
                    },
                    onFailure: (fail) =>
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Lỗi: ${fail.message}')),
                        ),
                  );
                },
                width: double.infinity,
              ),
            ],
          ),
        );
      },
    );
  }
}
