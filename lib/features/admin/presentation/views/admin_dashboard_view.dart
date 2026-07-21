import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../auth/domain/models/app_user_role.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../commerce/domain/models/app_order.dart';
import '../../../commerce/domain/models/product.dart';
import '../providers/admin_providers.dart';

class _AdminSection {
  final String label;
  final IconData icon;

  const _AdminSection(this.label, this.icon);
}

class AdminDashboardView extends ConsumerStatefulWidget {
  const AdminDashboardView({super.key});

  @override
  ConsumerState<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends ConsumerState<AdminDashboardView> {
  int _selectedSection = 0;
  final _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'VND',
    decimalDigits: 0,
  );

  static const _sections = [
    _AdminSection('Tổng quan', Icons.dashboard_rounded),
    _AdminSection('Chi nhánh', Icons.storefront_rounded),
    _AdminSection('Kho hàng', Icons.inventory_2_rounded),
    _AdminSection('Yêu cầu nhập hàng', Icons.add_business_rounded),
    _AdminSection('Khách hàng', Icons.people_alt_rounded),
    _AdminSection('Đơn hàng', Icons.receipt_long_rounded),
    _AdminSection('Nhật ký', Icons.history_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selected = _sections[_selectedSection];

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        titleSpacing: AppSpacing.lg,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bảng quản trị',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(selected.label, style: theme.textTheme.bodySmall),
          ],
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
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 760;
          final content = AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: KeyedSubtree(
              key: ValueKey(_selectedSection),
              child: _buildSelectedSection(),
            ),
          );

          if (!wide) return content;

          return Row(
            children: [
              _AdminSideNav(
                selectedIndex: _selectedSection,
                sections: _sections,
                onSelected: (index) => setState(() => _selectedSection = index),
              ),
              VerticalDivider(
                width: 1,
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
              Expanded(child: content),
            ],
          );
        },
      ),
      bottomNavigationBar: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 760) return const SizedBox.shrink();
          return NavigationBar(
            selectedIndex: _selectedSection > 3 ? 3 : _selectedSection,
            height: 72,
            onDestinationSelected: (index) {
              if (index < 3) {
                setState(() => _selectedSection = index);
                return;
              }
              _showMoreSections();
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_rounded),
                label: 'Tổng quan',
              ),
              NavigationDestination(
                icon: Icon(Icons.storefront_rounded),
                label: 'Chi nhánh',
              ),
              NavigationDestination(
                icon: Icon(Icons.inventory_2_rounded),
                label: 'Kho hàng',
              ),
              NavigationDestination(
                icon: Icon(Icons.more_horiz_rounded),
                label: 'Thêm',
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSelectedSection() {
    switch (_selectedSection) {
      case 0:
        return _buildOverviewTab();
      case 1:
        return _buildBranchesTab();
      case 2:
        return _buildInventoryTab();
      case 3:
        return _buildStockRequestsTab();
      case 4:
        return _buildCustomersTab();
      case 5:
        return _buildOrdersTab();
      case 6:
        return _buildAuditLogsTab();
      default:
        return _buildOverviewTab();
    }
  }

  void _showMoreSections() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _sections.length - 3,
            itemBuilder: (context, index) {
              final sectionIndex = index + 3;
              final section = _sections[sectionIndex];
              return ListTile(
                leading: Icon(section.icon),
                title: Text(section.label),
                selected: _selectedSection == sectionIndex,
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _selectedSection = sectionIndex);
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildOverviewTab() {
    final usersAsync = ref.watch(allUsersProvider);
    final ordersAsync = ref.watch(allOrdersProvider);

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
            final branchCount = users.where(_isCompanyBranchUser).length;
            final customerCount = users
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
                    'Vận hành thương hiệu',
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
                        title: 'Doanh thu hoàn tất',
                        value: _currencyFormat.format(totalRevenue),
                        icon: Icons.monetization_on_rounded,
                        color: Colors.green,
                      ),
                      _buildStatCard(
                        title: 'Tổng đơn hàng',
                        value: '${orders.length}',
                        icon: Icons.receipt_rounded,
                        color: Colors.blue,
                      ),
                      _buildStatCard(
                        title: 'Chi nhánh',
                        value: '$branchCount',
                        icon: Icons.storefront_rounded,
                        color: Colors.purple,
                      ),
                      _buildStatCard(
                        title: 'Khách hàng',
                        value: '$customerCount',
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
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: AppSpacing.xs),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: AppSpacing.xs),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
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

  Widget _buildBranchesTab() {
    final usersAsync = ref.watch(allUsersProvider);
    return usersAsync.when(
      loading: () => const LoadingView(),
      error: (err, stack) => ErrorView(
        message: err.toString(),
        onRetry: () => ref.refresh(allUsersProvider),
      ),
      data: (users) {
        final branches = users.where(_isCompanyBranchUser).toList();
        if (branches.isEmpty) {
          return const EmptyView(
            title: 'Chưa có chi nhánh',
            description: 'Tài khoản chi nhánh của công ty sẽ hiển thị tại đây.',
            icon: Icons.storefront_rounded,
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(allUsersProvider),
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: branches.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final branch = branches[index];
              final isBlocked =
                  branch.status == 'blocked' || branch.status == 'locked';
              return _UserTile(
                name: branch.displayName.isEmpty
                    ? 'Chi nhánh chưa đặt tên'
                    : branch.displayName,
                email: branch.email,
                roleLabel: 'Chi nhánh',
                isBlocked: isBlocked,
                icon: Icons.storefront_rounded,
                onToggleStatus: () =>
                    _toggleUserStatus(branch.uid, isBlocked, 'branch'),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildInventoryTab() {
    final productsAsync = ref.watch(allProductsProvider);
    final usersAsync = ref.watch(allUsersProvider);
    return productsAsync.when(
      loading: () => const LoadingView(),
      error: (err, stack) => ErrorView(
        message: err.toString(),
        onRetry: () => ref.refresh(allProductsProvider),
      ),
      data: (products) {
        final branches =
            usersAsync.valueOrNull?.where(_isCompanyBranchUser).toList() ??
            const [];
        final importButton = Align(
          alignment: Alignment.centerLeft,
          child: AppButton(
            text: 'Nhập sản phẩm',
            icon: const Icon(Icons.add_rounded, size: 18),
            onPressed: () => _showImportProductDialog(branches),
          ),
        );

        if (products.isEmpty) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                importButton,
                const SizedBox(height: AppSpacing.xl),
                const EmptyView(
                  title: 'Chưa có hàng trong kho',
                  description:
                      'Nhập sản phẩm thương hiệu và phân bổ tồn kho cho chi nhánh.',
                  icon: Icons.inventory_2_outlined,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(allProductsProvider),
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: products.length + 1,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              if (index == 0) return importButton;
              final productIndex = index - 1;
              final product = products[productIndex];
              final totalStock = product.variants.fold<int>(
                0,
                (sum, item) => sum + item.stockQuantity,
              );
              final stockColor = totalStock == 0
                  ? AppColors.error
                  : totalStock <= 5
                  ? Colors.orange
                  : AppColors.success;
              final stockLabel = totalStock == 0
                  ? 'Hết hàng'
                  : totalStock <= 5
                  ? 'Sắp hết ($totalStock)'
                  : 'Còn hàng ($totalStock)';

              return Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: _panelDecoration(context),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(top: AppSpacing.md),
                  leading: CircleAvatar(
                    backgroundColor: stockColor.withValues(alpha: 0.12),
                    foregroundColor: stockColor,
                    child: const Icon(Icons.inventory_2_rounded),
                  ),
                  title: Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        _InfoChip(
                          text: _currencyFormat.format(product.basePrice),
                        ),
                        _InfoChip(text: stockLabel),
                        _InfoChip(text: product.status.nameVi),
                      ],
                    ),
                  ),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Mô tả: ${product.description}'),
                          const SizedBox(height: AppSpacing.xs),
                          Text('Mã sản phẩm: ${product.id}'),
                          Text('Đơn vị quản lý kho: ${product.sellerId}'),
                          const SizedBox(height: AppSpacing.md),
                          const Text(
                            'Tồn kho biến thể',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          if (product.variants.isEmpty)
                            const Text('Chưa cấu hình biến thể.')
                          else
                            _VariantTable(variants: product.variants),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildStockRequestsTab() {
    final requestsAsync = ref.watch(stockRequestsProvider);
    return requestsAsync.when(
      loading: () => const LoadingView(),
      error: (err, stack) => ErrorView(
        message: err.toString(),
        onRetry: () => ref.refresh(stockRequestsProvider),
      ),
      data: (requests) {
        if (requests.isEmpty) {
          return const EmptyView(
            title: 'Chưa có yêu cầu nhập hàng',
            description:
                'Yêu cầu bổ sung hàng từ chi nhánh sẽ hiển thị tại đây.',
            icon: Icons.add_business_rounded,
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(stockRequestsProvider),
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: requests.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final request = requests[index];
              final id = request['id']?.toString() ?? '';
              final productName =
                  request['productName']?.toString() ??
                  'Sản phẩm không xác định';
              final branchId = request['branchId']?.toString() ?? 'Không rõ';
              final quantity = request['requestedQuantity']?.toString() ?? '0';
              final note = request['note']?.toString() ?? '';
              final status = request['status']?.toString() ?? 'pending';
              final createdAt = request['createdAt'];
              final createdAtText = createdAt is DateTime
                  ? DateFormat('dd/MM/yyyy HH:mm').format(createdAt)
                  : 'Chưa có ngày';
              final statusColor = switch (status) {
                'approved' => AppColors.success,
                'rejected' => AppColors.error,
                _ => Colors.orange,
              };

              return Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: _panelDecoration(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusSm,
                            ),
                          ),
                          child: const Icon(Icons.inventory_2_rounded),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                productName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Chi nhánh: $branchId',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: [
                        _InfoChip(text: 'Số lượng: $quantity'),
                        _InfoChip(text: createdAtText),
                        _InfoChip(
                          text: _stockRequestStatusText(status),
                          color: statusColor,
                        ),
                      ],
                    ),
                    if (note.trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(note, style: Theme.of(context).textTheme.bodySmall),
                    ],
                    if (status == 'pending') ...[
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          AppButton(
                            text: 'Duyệt',
                            icon: const Icon(Icons.check_rounded, size: 18),
                            onPressed: () =>
                                _updateStockRequestStatus(id, 'approved'),
                          ),
                          AppButton(
                            text: 'Từ chối',
                            icon: const Icon(Icons.close_rounded, size: 18),
                            variant: AppButtonVariant.outlined,
                            onPressed: () =>
                                _updateStockRequestStatus(id, 'rejected'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCustomersTab() {
    final usersAsync = ref.watch(allUsersProvider);
    return usersAsync.when(
      loading: () => const LoadingView(),
      error: (err, stack) => ErrorView(
        message: err.toString(),
        onRetry: () => ref.refresh(allUsersProvider),
      ),
      data: (users) {
        final customers = users
            .where((u) => u.role == AppUserRole.user)
            .toList();
        if (customers.isEmpty) {
          return const EmptyView(
            title: 'Chưa có khách hàng',
            description: 'Tài khoản khách hàng sẽ hiển thị tại đây.',
            icon: Icons.people_alt_rounded,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: customers.length,
          separatorBuilder: (context, index) =>
              const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final user = customers[index];
            final isBlocked =
                user.status == 'blocked' || user.status == 'locked';
            return _UserTile(
              name: user.displayName.isEmpty
                  ? 'Khách hàng chưa đặt tên'
                  : user.displayName,
              email: user.email,
              roleLabel: user.role.nameVi,
              isBlocked: isBlocked,
              icon: Icons.person_rounded,
              onToggleStatus: () =>
                  _toggleUserStatus(user.uid, isBlocked, 'account'),
            );
          },
        );
      },
    );
  }

  Widget _buildOrdersTab() {
    final ordersAsync = ref.watch(allOrdersProvider);
    return ordersAsync.when(
      loading: () => const LoadingView(),
      error: (err, stack) => ErrorView(
        message: err.toString(),
        onRetry: () => ref.refresh(allOrdersProvider),
      ),
      data: (orders) {
        if (orders.isEmpty) {
          return const EmptyView(
            title: 'Chưa có đơn hàng',
            description: 'Đơn hàng của khách sẽ hiển thị tại đây.',
            icon: Icons.receipt_long_outlined,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: orders.length,
          separatorBuilder: (context, index) =>
              const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final order = orders[index];
            return Card(
              child: ListTile(
                title: Text('Đơn hàng: ${order.id}'),
                subtitle: Text(
                  'Tổng: ${_currencyFormat.format(order.totalAmount)} | Trạng thái: ${order.status.nameVi}',
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showOrderDialog(order),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAuditLogsTab() {
    final logsAsync = ref.watch(auditLogsProvider);
    return logsAsync.when(
      loading: () => const LoadingView(),
      error: (err, stack) => ErrorView(
        message: 'Không thể tải nhật ký. Vui lòng kiểm tra quyền Firestore.',
        onRetry: () => ref.refresh(auditLogsProvider),
      ),
      data: (logs) {
        if (logs.isEmpty) {
          return const EmptyView(
            title: 'Chưa có nhật ký',
            description: 'Thao tác quản trị sẽ hiển thị tại đây.',
            icon: Icons.history_rounded,
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(auditLogsProvider),
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: logs.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final log = logs[index];
              final timeText = DateFormat(
                'dd/MM/yyyy HH:mm',
              ).format(log.createdAt);
              return Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: _panelDecoration(context),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.borderDark
                            : AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSm,
                        ),
                      ),
                      child: const Icon(Icons.history_rounded, size: 20),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            log.action,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            '${log.targetType} - ${log.targetId}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Wrap(
                            spacing: AppSpacing.xs,
                            runSpacing: AppSpacing.xs,
                            children: [
                              _InfoChip(text: log.actorRole),
                              _InfoChip(text: timeText),
                            ],
                          ),
                          if (log.reason?.trim().isNotEmpty ?? false) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              log.reason!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _toggleUserStatus(
    String userId,
    bool isBlocked,
    String label,
  ) async {
    final repo = ref.read(adminRepositoryProvider);
    final result = await repo.updateUserStatus(
      userId,
      isBlocked ? 'active' : 'blocked',
    );
    if (!mounted) return;
    result.when(
      onSuccess: (_) {
        ref.invalidate(allUsersProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isBlocked ? 'Đã mở khóa $label' : 'Đã khóa $label'),
          ),
        );
      },
      onFailure: (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: AppColors.error,
          ),
        );
      },
    );
  }

  Future<void> _updateStockRequestStatus(
    String requestId,
    String status,
  ) async {
    if (requestId.isEmpty) return;
    final repo = ref.read(adminRepositoryProvider);
    final result = await repo.updateStockRequestStatus(requestId, status);
    if (!mounted) return;
    result.when(
      onSuccess: (_) {
        ref.invalidate(stockRequestsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Yêu cầu nhập hàng: ${_stockRequestStatusText(status)}',
            ),
          ),
        );
      },
      onFailure: (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: AppColors.error,
          ),
        );
      },
    );
  }

  Future<void> _showImportProductDialog(List<dynamic> branches) async {
    final imported = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _AdminProductImportDialog(branches: branches);
      },
    );

    if (!mounted || imported != true) return;
    ref.invalidate(allProductsProvider);
    ref.invalidate(auditLogsProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã nhập sản phẩm vào kho thương hiệu'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _showOrderDialog(AppOrder order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Chi tiết đơn hàng: ${order.id}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mã khách hàng: ${order.userId}'),
              Text('Trạng thái: ${order.status.nameVi}'),
              Text('Tổng cộng: ${_currencyFormat.format(order.totalAmount)}'),
              Text('Thanh toán: ${order.paymentMethod}'),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Thông tin nhận hàng:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Tên: ${order.shippingAddress.fullName}'),
              Text('Số điện thoại: ${order.shippingAddress.phone}'),
              Text(
                'Địa chỉ: ${order.shippingAddress.addressLine}, ${order.shippingAddress.city}',
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Sản phẩm:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...order.items.map(
                (item) => Text(
                  '- ${item.productName} (x${item.quantity}) - ${_currencyFormat.format(item.price)}',
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
  }

  BoxDecoration _panelDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? AppColors.surfaceDark : Colors.white,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      border: Border.all(
        color: isDark ? AppColors.borderDark : AppColors.borderLight,
      ),
    );
  }
}

class _AdminProductImportDialog extends ConsumerStatefulWidget {
  final List<dynamic> branches;

  const _AdminProductImportDialog({required this.branches});

  @override
  ConsumerState<_AdminProductImportDialog> createState() =>
      _AdminProductImportDialogState();
}

class _AdminProductImportDialogState
    extends ConsumerState<_AdminProductImportDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageController = TextEditingController();
  final _variantRows = <_VariantDraft>[];
  final _branchStockControllers = <String, TextEditingController>{};

  String? _categoryId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _variantRows.add(_VariantDraft());
    for (final branch in widget.branches) {
      _branchStockControllers[branch.uid.toString()] = TextEditingController(
        text: '0',
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageController.dispose();
    for (final row in _variantRows) {
      row.dispose();
    }
    for (final controller in _branchStockControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final basePrice = double.tryParse(_priceController.text.trim());
    if (basePrice == null) return;

    final variants = <ProductVariant>[];
    var index = 1;
    for (final row in _variantRows) {
      final stock = int.tryParse(row.stockController.text.trim()) ?? 0;
      variants.add(
        ProductVariant(
          id: const Uuid().v4(),
          size: row.sizeController.text.trim(),
          color: row.colorController.text.trim(),
          sku: row.skuController.text.trim().isEmpty
              ? 'SKU-${DateTime.now().millisecondsSinceEpoch}-$index'
              : row.skuController.text.trim(),
          stockQuantity: stock,
          priceDifference:
              double.tryParse(row.priceDiffController.text.trim()) ?? 0,
        ),
      );
      index++;
    }

    final branchInventory = widget.branches.map<Map<String, dynamic>>((branch) {
      final branchId = branch.uid.toString();
      final stock =
          int.tryParse(_branchStockControllers[branchId]?.text.trim() ?? '0') ??
          0;
      return {
        'branchId': branchId,
        'storeId': branchId,
        'branchName': branch.displayName.toString().isEmpty
            ? branch.email.toString()
            : branch.displayName.toString(),
        'address': '',
        'stockQuantity': stock,
      };
    }).toList();

    setState(() => _isSaving = true);
    final product = Product(
      id: const Uuid().v4(),
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      categoryId: _categoryId ?? 'cat-fashion',
      basePrice: basePrice,
      sellerId: 'admin',
      status: ProductStatus.published,
      images: _imageController.text.trim().isEmpty
          ? const []
          : [_imageController.text.trim()],
      isAvailable: true,
      createdAt: DateTime.now(),
      variants: variants,
    );

    final result = await ref
        .read(adminRepositoryProvider)
        .importBrandProduct(product, branchInventory: branchInventory);

    if (!mounted) return;
    setState(() => _isSaving = false);
    result.when(
      onSuccess: (_) => Navigator.pop(context, true),
      onFailure: (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: AppColors.error,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(adminCategoriesProvider);
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.md),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 820),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Nhập sản phẩm',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Đóng',
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    AppTextField(
                      controller: _nameController,
                      labelText: 'Tên sản phẩm',
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Nhập tên sản phẩm'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _descriptionController,
                      labelText: 'Mô tả',
                      maxLines: 3,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Nhập mô tả'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _priceController,
                      labelText: 'Giá bán VND',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final price = double.tryParse(value?.trim() ?? '');
                        return price == null || price <= 0
                            ? 'Giá không hợp lệ'
                            : null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    categoriesAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (err, stack) => Text(
                        'Không tải được danh mục: $err',
                        style: const TextStyle(color: AppColors.error),
                      ),
                      data: (categories) {
                        if (_categoryId == null && categories.isNotEmpty) {
                          _categoryId = categories.first.id;
                        }
                        return DropdownButtonFormField<String>(
                          initialValue: _categoryId,
                          decoration: const InputDecoration(
                            labelText: 'Danh mục',
                          ),
                          items: categories
                              .map(
                                (category) => DropdownMenuItem(
                                  value: category.id,
                                  child: Text(category.name),
                                ),
                              )
                              .toList(),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Chọn danh mục'
                              : null,
                          onChanged: (value) {
                            setState(() => _categoryId = value);
                          },
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _imageController,
                      labelText: 'Ảnh sản phẩm (URL)',
                      hintText: 'https://...',
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _SectionTitle(
                      title: 'Biến thể',
                      action: TextButton.icon(
                        onPressed: _addVariantRow,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Thêm'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    for (var i = 0; i < _variantRows.length; i++) ...[
                      _VariantDraftCard(
                        index: i,
                        row: _variantRows[i],
                        canRemove: _variantRows.length > 1,
                        onRemove: () => _removeVariantRow(i),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    const _SectionTitle(title: 'Phân bổ tồn kho chi nhánh'),
                    const SizedBox(height: AppSpacing.sm),
                    if (widget.branches.isEmpty)
                      const Text('Chưa có tài khoản chi nhánh.')
                    else
                      ...widget.branches.map((branch) {
                        final branchId = branch.uid.toString();
                        final name = branch.displayName.toString().isEmpty
                            ? branch.email.toString()
                            : branch.displayName.toString();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              SizedBox(
                                width: 110,
                                child: TextFormField(
                                  controller: _branchStockControllers[branchId],
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Số lượng',
                                  ),
                                  validator: (value) {
                                    final stock = int.tryParse(
                                      value?.trim() ?? '0',
                                    );
                                    return stock == null || stock < 0
                                        ? 'Sai'
                                        : null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: 'Hủy',
                      variant: AppButtonVariant.outlined,
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppButton(
                      text: 'Nhập hàng',
                      isLoading: _isSaving,
                      icon: const Icon(Icons.upload_rounded, size: 18),
                      onPressed: _save,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addVariantRow() {
    setState(() => _variantRows.add(_VariantDraft()));
  }

  void _removeVariantRow(int index) {
    if (_variantRows.length <= 1) return;
    final row = _variantRows.removeAt(index);
    row.dispose();
    setState(() {});
  }
}

class _VariantDraft {
  final sizeController = TextEditingController(text: 'Default');
  final colorController = TextEditingController(text: 'Default');
  final skuController = TextEditingController();
  final stockController = TextEditingController(text: '0');
  final priceDiffController = TextEditingController(text: '0');

  void dispose() {
    sizeController.dispose();
    colorController.dispose();
    skuController.dispose();
    stockController.dispose();
    priceDiffController.dispose();
  }
}

class _VariantDraftCard extends StatelessWidget {
  final int index;
  final _VariantDraft row;
  final bool canRemove;
  final VoidCallback onRemove;

  const _VariantDraftCard({
    required this.index,
    required this.row,
    required this.canRemove,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderLight),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Biến thể ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                tooltip: 'Xóa biến thể',
                onPressed: canRemove ? onRemove : null,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 520;
              final fields = [
                _SmallTextField(
                  controller: row.sizeController,
                  label: 'Kích cỡ',
                  validator: _requiredText,
                ),
                _SmallTextField(
                  controller: row.colorController,
                  label: 'Màu',
                  validator: _requiredText,
                ),
                _SmallTextField(
                  controller: row.skuController,
                  label: 'SKU',
                  validator: _requiredText,
                ),
                _SmallTextField(
                  controller: row.stockController,
                  label: 'Tồn kho',
                  keyboardType: TextInputType.number,
                  validator: _nonNegativeInt,
                ),
                _SmallTextField(
                  controller: row.priceDiffController,
                  label: '+ Giá',
                  keyboardType: TextInputType.number,
                  validator: _numberText,
                ),
              ];

              if (compact) {
                return Column(
                  children: fields
                      .map(
                        (field) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: field,
                        ),
                      )
                      .toList(),
                );
              }

              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: fields
                    .map((field) => SizedBox(width: 160, child: field))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SmallTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType keyboardType;
  final FormFieldValidator<String>? validator;

  const _SmallTextField({
    required this.controller,
    required this.label,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label),
      validator: validator,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final Widget? action;

  const _SectionTitle({required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        ...?action == null ? null : [action!],
      ],
    );
  }
}

String? _requiredText(String? value) {
  return value == null || value.trim().isEmpty ? 'Bắt buộc' : null;
}

String _stockRequestStatusText(String status) {
  switch (status) {
    case 'approved':
      return 'Đã duyệt';
    case 'rejected':
      return 'Từ chối';
    default:
      return 'Đang chờ';
  }
}

String? _nonNegativeInt(String? value) {
  final parsed = int.tryParse(value?.trim() ?? '');
  return parsed == null || parsed < 0 ? 'Không hợp lệ' : null;
}

String? _numberText(String? value) {
  final parsed = double.tryParse(value?.trim() ?? '');
  return parsed == null ? 'Không hợp lệ' : null;
}

bool _isCompanyBranchUser(dynamic user) {
  if (user.role != AppUserRole.seller) return false;
  final email = user.email.toString().toLowerCase();
  final name = user.displayName.toString().toLowerCase();
  return email.startsWith('branch.') ||
      name.startsWith('chi nhanh') ||
      name.startsWith('chi nhánh');
}

class _AdminSideNav extends StatelessWidget {
  final int selectedIndex;
  final List<_AdminSection> sections;
  final ValueChanged<int> onSelected;

  const _AdminSideNav({
    required this.selectedIndex,
    required this.sections,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 236,
      padding: const EdgeInsets.all(AppSpacing.md),
      color: isDark ? AppColors.surfaceDark : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quản lý',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: ListView.separated(
              itemCount: sections.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppSpacing.xs),
              itemBuilder: (context, index) {
                final section = sections[index];
                final selected = selectedIndex == index;
                return Material(
                  color: selected
                      ? (isDark ? AppColors.borderDark : AppColors.primaryLight)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    onTap: () => onSelected(index),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            section.icon,
                            size: 20,
                            color: selected ? AppColors.primary : null,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              section.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: selected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: selected ? AppColors.primary : null,
                              ),
                            ),
                          ),
                        ],
                      ),
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
}

class _UserTile extends StatelessWidget {
  final String name;
  final String email;
  final String roleLabel;
  final bool isBlocked;
  final IconData icon;
  final VoidCallback onToggleStatus;

  const _UserTile({
    required this.name,
    required this.email,
    required this.roleLabel,
    required this.isBlocked,
    required this.icon,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.surfaceDark
            : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.borderDark
              : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isBlocked
                ? AppColors.error.withValues(alpha: 0.12)
                : AppColors.primary.withValues(alpha: 0.12),
            foregroundColor: isBlocked ? AppColors.error : AppColors.primary,
            child: Icon(icon),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    decoration: isBlocked ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  children: [
                    _InfoChip(text: roleLabel),
                    _InfoChip(text: isBlocked ? 'Đã khóa' : 'Đang hoạt động'),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: isBlocked ? 'Mở khóa' : 'Khóa',
            icon: Icon(
              isBlocked ? Icons.lock_open_rounded : Icons.lock_rounded,
              color: isBlocked ? AppColors.success : AppColors.error,
            ),
            onPressed: onToggleStatus,
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String text;
  final Color? color;

  const _InfoChip({required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _VariantTable extends StatelessWidget {
  final List<dynamic> variants;

  const _VariantTable({required this.variants});

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(3),
        3: FlexColumnWidth(2),
      },
      border: TableBorder.all(color: Colors.grey, width: 0.4),
      children: [
        const TableRow(
          children: [
            _TableCell('Kích cỡ', bold: true),
            _TableCell('Màu', bold: true),
            _TableCell('SKU', bold: true),
            _TableCell('Tồn kho', bold: true),
          ],
        ),
        ...variants.map((variant) {
          return TableRow(
            children: [
              _TableCell(variant.size),
              _TableCell(variant.color),
              _TableCell(variant.sku),
              _TableCell(
                '${variant.stockQuantity}',
                color: variant.stockQuantity == 0 ? AppColors.error : null,
                bold: true,
              ),
            ],
          );
        }),
      ],
    );
  }
}

class _TableCell extends StatelessWidget {
  final String text;
  final bool bold;
  final Color? color;

  const _TableCell(this.text, {this.bold = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontWeight: bold ? FontWeight.w800 : FontWeight.normal,
          fontSize: 12,
        ),
      ),
    );
  }
}
