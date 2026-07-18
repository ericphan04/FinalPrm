import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../domain/models/app_order.dart';
import '../providers/commerce_providers.dart';

class CheckoutView extends ConsumerStatefulWidget {
  const CheckoutView({super.key});

  @override
  ConsumerState<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends ConsumerState<CheckoutView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;
    
    final cartState = ref.read(cartControllerProvider);
    if (cartState.items.isEmpty) return;

    final address = ShippingAddress(
      fullName: _nameController.text,
      phone: _phoneController.text,
      addressLine: _addressController.text,
      city: _cityController.text,
    );

    final success = await ref.read(orderControllerProvider.notifier).createCheckout(
      cartState.items,
      address,
      'COD', // Currently only COD supported
    );

    if (success && mounted) {
      await ref.read(cartControllerProvider.notifier).mergeCart(); // Clear local cart effectively
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => ConfirmDialog(
          title: 'Đặt hàng thành công',
          content: 'Đơn hàng của bạn đã được xác nhận. Vui lòng theo dõi trong mục Đơn hàng.',
          confirmText: 'Xem đơn hàng',
          cancelText: 'Về trang chủ',
          onConfirm: () {
            context.go('/orders');
          },
        ),
      ).then((_) {
        // Fallback if dialog dismissed
        if (context.mounted) context.go('/');
      });
    } else if (mounted) {
      final error = ref.read(orderControllerProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error ?? 'Lỗi đặt hàng')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartControllerProvider);
    final orderState = ref.watch(orderControllerProvider);
    final theme = Theme.of(context);
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Thông tin giao hàng', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _nameController,
                labelText: 'Họ và tên',
                validator: (v) => v!.isEmpty ? 'Vui lòng nhập tên' : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                controller: _phoneController,
                labelText: 'Số điện thoại',
                keyboardType: TextInputType.phone,
                validator: (v) => v!.length < 10 ? 'SĐT không hợp lệ' : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                controller: _cityController,
                labelText: 'Tỉnh/Thành phố',
                validator: (v) => v!.isEmpty ? 'Vui lòng nhập thành phố' : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                controller: _addressController,
                labelText: 'Địa chỉ cụ thể (Số nhà, đường)',
                validator: (v) => v!.isEmpty ? 'Vui lòng nhập địa chỉ' : null,
              ),
              
              const SizedBox(height: AppSpacing.lg),
              Text('Phương thức thanh toán', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.sm),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.money, color: AppColors.primary),
                title: const Text('Thanh toán khi nhận hàng (COD)'),
                trailing: const Icon(Icons.check_circle, color: AppColors.success),
              ),
              
              const SizedBox(height: AppSpacing.lg),
              Text('Tóm tắt đơn hàng', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.sm),
              ...cartState.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text('${item.quantity}x ${item.productName} (${item.size}, ${item.color})')),
                    Text(currencyFormatter.format(item.price * item.quantity)),
                  ],
                ),
              )),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tổng cộng:', style: theme.textTheme.titleMedium),
                  Text(
                    currencyFormatter.format(cartState.totalAmount),
                    style: theme.textTheme.titleLarge?.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: AppButton(
            text: 'Xác nhận đặt hàng',
            isLoading: orderState.isLoading,
            onPressed: cartState.items.isEmpty ? null : _submitOrder,
          ),
        ),
      ),
    );
  }
}
