import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/models/app_order.dart';

class OrderSuccessView extends StatelessWidget {
  final AppOrder order;

  const OrderSuccessView({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
    );

    return Scaffold(
      backgroundColor: theme.brightness == Brightness.dark 
          ? AppColors.backgroundDark 
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Hoàn tất đơn hàng'),
        automaticallyImplyLeading: false, // Prevent going back to checkout
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: AppSpacing.lg),
            // Success Icon
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 80,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Đặt hàng thành công!',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Cảm ơn bạn đã mua sắm tại Sneaker Kings.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Receipt Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark 
                    ? AppColors.surfaceDark 
                    : Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadowColor,
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'HÓA ĐƠN',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const Divider(height: AppSpacing.xl),
                  _buildInfoRow('Mã đơn hàng', order.id.toUpperCase(), theme),
                  const SizedBox(height: AppSpacing.sm),
                  _buildInfoRow('Ngày đặt', DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt), theme),
                  const SizedBox(height: AppSpacing.sm),
                  _buildInfoRow('Phương thức', 'Thanh toán khi nhận hàng (COD)', theme),
                  
                  const Divider(height: AppSpacing.xl),
                  Text('Thông tin giao hàng', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: AppSpacing.sm),
                  Text(order.shippingAddress.fullName, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  Text(order.shippingAddress.phone, style: theme.textTheme.bodyMedium),
                  Text('${order.shippingAddress.addressLine}, ${order.shippingAddress.city}', style: theme.textTheme.bodyMedium),
                  
                  const Divider(height: AppSpacing.xl),
                  Text('Sản phẩm', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: AppSpacing.sm),
                  ...order.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${item.quantity}x ', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.productName, style: theme.textTheme.bodyMedium),
                              Text('${item.size} - ${item.color}', style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ),
                        Text(currencyFormatter.format(item.price * item.quantity), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )),
                  const Divider(height: AppSpacing.xl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tổng cộng', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Text(
                        currencyFormatter.format(order.totalAmount),
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Actions
            AppButton(
              text: 'Tiếp tục mua sắm',
              onPressed: () => context.go('/'),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              text: 'Xem đơn hàng',
              variant: AppButtonVariant.outlined,
              onPressed: () => context.go('/orders'),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
