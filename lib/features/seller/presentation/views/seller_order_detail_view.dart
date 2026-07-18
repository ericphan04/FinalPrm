import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../commerce/domain/models/app_order.dart';
import '../providers/seller_providers.dart';

class SellerOrderDetailView extends ConsumerWidget {
  final AppOrder order;

  const SellerOrderDetailView({super.key, required this.order});

  void _updateStatus(
    BuildContext context,
    WidgetRef ref,
    OrderStatus nextStatus,
  ) {
    ref
        .read(sellerOrderControllerProvider.notifier)
        .updateOrderStatus(order.id, nextStatus)
        .then((success) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Đã chuyển đơn hàng sang trạng thái: ${_getOrderStatusNameVi(nextStatus)}',
                ),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.pop(context);
          }
        });
  }

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

    // Watch error messages
    ref.listen(sellerOrderControllerProvider, (previous, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    // Determine what actions are available based on current status
    Widget actionsArea;
    if (order.status == OrderStatus.pending) {
      actionsArea = Row(
        children: [
          Expanded(
            child: AppButton(
              text: 'Hủy đơn',
              onPressed: () =>
                  _updateStatus(context, ref, OrderStatus.cancelled),
              variant: AppButtonVariant.outlined,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: AppButton(
              text: 'Xác nhận đơn',
              onPressed: () =>
                  _updateStatus(context, ref, OrderStatus.confirmed),
              variant: AppButtonVariant.primary,
            ),
          ),
        ],
      );
    } else if (order.status == OrderStatus.confirmed) {
      actionsArea = Row(
        children: [
          Expanded(
            child: AppButton(
              text: 'Hủy đơn',
              onPressed: () =>
                  _updateStatus(context, ref, OrderStatus.cancelled),
              variant: AppButtonVariant.outlined,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: AppButton(
              text: 'Gửi hàng',
              onPressed: () =>
                  _updateStatus(context, ref, OrderStatus.shipping),
              variant: AppButtonVariant.primary,
            ),
          ),
        ],
      );
    } else if (order.status == OrderStatus.shipping) {
      actionsArea = Row(
        children: [
          Expanded(
            child: AppButton(
              text: 'Hủy đơn',
              onPressed: () =>
                  _updateStatus(context, ref, OrderStatus.cancelled),
              variant: AppButtonVariant.outlined,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: AppButton(
              text: 'Giao thành công',
              onPressed: () =>
                  _updateStatus(context, ref, OrderStatus.completed),
              variant: AppButtonVariant.primary,
            ),
          ),
        ],
      );
    } else {
      actionsArea = Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color:
              (order.status == OrderStatus.completed
                      ? AppColors.success
                      : AppColors.error)
                  .withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        width: double.infinity,
        child: Center(
          child: Text(
            order.status == OrderStatus.completed
                ? 'Đơn hàng này đã hoàn thành.'
                : 'Đơn hàng này đã bị hủy bỏ.',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: order.status == OrderStatus.completed
                  ? AppColors.success
                  : AppColors.error,
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text('Đơn hàng: #${order.id.substring(0, 8).toUpperCase()}'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Status card
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadowColor,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Trạng thái hiện tại:',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getOrderStatusNameVi(order.status).toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: _getOrderStatusColor(order.status),
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        Icons.receipt_rounded,
                        size: 40,
                        color: _getOrderStatusColor(
                          order.status,
                        ).withOpacity(0.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Customer info
                Text(
                  'Thông tin giao nhận',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      children: [
                        _buildDetailItem(
                          context,
                          'Họ và tên',
                          order.shippingAddress.fullName,
                        ),
                        const Divider(),
                        _buildDetailItem(
                          context,
                          'Số điện thoại',
                          order.shippingAddress.phone,
                        ),
                        const Divider(),
                        _buildDetailItem(
                          context,
                          'Tỉnh/TP',
                          order.shippingAddress.city,
                        ),
                        const Divider(),
                        _buildDetailItem(
                          context,
                          'Địa chỉ chi tiết',
                          order.shippingAddress.addressLine,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Items list
                Text(
                  'Danh mục sản phẩm',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: order.items.length,
                  itemBuilder: (context, index) {
                    final item = order.items[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[200],
                                child: item.imageUrl.isNotEmpty
                                    ? Image.network(
                                        item.imageUrl,
                                        fit: BoxFit.cover,
                                      )
                                    : const Icon(
                                        Icons.image,
                                        color: Colors.grey,
                                      ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Size: ${item.size} - Màu: ${item.color}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Số lượng: x${item.quantity}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              currencyFormatter.format(item.price),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.xl),

                // Order metadata
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      children: [
                        _buildDetailItem(
                          context,
                          'Phương thức thanh toán',
                          order.paymentMethod,
                        ),
                        const Divider(),
                        _buildDetailItem(
                          context,
                          'Tổng giá trị đơn hàng',
                          currencyFormatter.format(order.totalAmount),
                          isBold: true,
                        ),
                        const Divider(),
                        _buildDetailItem(
                          context,
                          'Ngày đặt hàng',
                          DateFormat(
                            'dd/MM/yyyy HH:mm',
                          ).format(order.createdAt),
                        ),
                        if (order.updatedAt != null) ...[
                          const Divider(),
                          _buildDetailItem(
                            context,
                            'Cập nhật lần cuối',
                            DateFormat(
                              'dd/MM/yyyy HH:mm',
                            ).format(order.updatedAt!),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Action area
                actionsArea,
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
        if (state.isLoading)
          const LoadingView(
            message: 'Đang chuyển trạng thái...',
            isOverlay: true,
          ),
      ],
    );
  }

  Widget _buildDetailItem(
    BuildContext context,
    String label,
    String value, {
    bool isBold = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              fontSize: 13,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
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

  Color _getOrderStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.shipping:
        return Colors.purple;
      case OrderStatus.completed:
        return AppColors.success;
      case OrderStatus.cancelled:
        return AppColors.error;
    }
  }
}
