import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/models/app_order.dart';
import '../providers/commerce_providers.dart';

enum _FulfillmentMethod { delivery, pickup }

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

  late final Future<List<_PickupBranch>> _branchesFuture;
  _FulfillmentMethod _fulfillmentMethod = _FulfillmentMethod.delivery;
  _PickupBranch? _selectedBranch;

  @override
  void initState() {
    super.initState();
    _branchesFuture = _loadPickupBranches();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<List<_PickupBranch>> _loadPickupBranches() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('stores')
        .get()
        .timeout(const Duration(seconds: 10));

    final branches = snapshot.docs
        .where((doc) {
          final data = doc.data();
          final slug = _stringValue(data['slug'], '').toLowerCase();
          final name = _stringValue(
            data['name'] ?? data['displayName'],
            '',
          ).toLowerCase();
          return slug.startsWith('chi-nhanh-') || name.startsWith('chi nhánh');
        })
        .map((doc) {
          final data = doc.data();
          return _PickupBranch(
            id: doc.id,
            name: _stringValue(
              data['name'] ?? data['displayName'],
              'Chi nhánh',
            ),
            address: _stringValue(data['address'], 'Chưa cập nhật địa chỉ'),
            phone: _stringValue(data['phone'], ''),
          );
        })
        .toList();

    branches.sort((a, b) => a.name.compareTo(b.name));
    return branches;
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final cartState = ref.read(cartControllerProvider);
    if (cartState.items.isEmpty) return;

    if (_fulfillmentMethod == _FulfillmentMethod.pickup &&
        _selectedBranch == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn chi nhánh nhận hàng')),
      );
      return;
    }

    final isPickup = _fulfillmentMethod == _FulfillmentMethod.pickup;
    final branch = _selectedBranch;
    final address = ShippingAddress(
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      addressLine: isPickup ? branch!.address : _addressController.text.trim(),
      city: isPickup ? 'Nhận tại cửa hàng' : _cityController.text.trim(),
    );

    final order = await ref
        .read(orderControllerProvider.notifier)
        .createCheckout(
          cartState.items,
          address,
          isPickup ? 'PAY_AT_STORE' : 'COD',
          fulfillmentMethod: isPickup ? 'pickup' : 'delivery',
          pickupStoreId: branch?.id,
          pickupStoreName: branch?.name,
          pickupAddress: branch?.address,
        );

    if (order != null && mounted) {
      await ref.read(cartControllerProvider.notifier).clearCart();

      if (!mounted) return;
      context.go('/order-success', extra: order);
    } else if (mounted) {
      final error = ref.read(orderControllerProvider).errorMessage;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error ?? 'Không thể đặt hàng')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartControllerProvider);
    final orderState = ref.watch(orderControllerProvider);
    final theme = Theme.of(context);
    final currencyFormatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'VND',
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Thông tin khách hàng',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _nameController,
                labelText: 'Họ và tên',
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Vui lòng nhập tên' : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                controller: _phoneController,
                labelText: 'Số điện thoại',
                keyboardType: TextInputType.phone,
                validator: (v) {
                  final value = v?.trim() ?? '';
                  return value.length < 10
                      ? 'Số điện thoại không hợp lệ'
                      : null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Cách nhận hàng',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _FulfillmentSelector(
                value: _fulfillmentMethod,
                onChanged: (value) {
                  setState(() => _fulfillmentMethod = value);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              if (_fulfillmentMethod == _FulfillmentMethod.delivery)
                _DeliveryFields(
                  cityController: _cityController,
                  addressController: _addressController,
                )
              else
                _PickupBranchPicker(
                  branchesFuture: _branchesFuture,
                  selectedBranch: _selectedBranch,
                  onSelected: (branch) {
                    setState(() => _selectedBranch = branch);
                  },
                ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Thanh toán',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.payments_outlined),
                title: Text(
                  _fulfillmentMethod == _FulfillmentMethod.pickup
                      ? 'Thanh toán khi nhận tại cửa hàng'
                      : 'Thanh toán khi nhận hàng (COD)',
                ),
                trailing: const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Tóm tắt đơn hàng',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...cartState.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item.quantity}x ${item.productName} (${item.size}, ${item.color})',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        currencyFormatter.format(item.price * item.quantity),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tổng cộng:', style: theme.textTheme.titleMedium),
                  Text(
                    currencyFormatter.format(cartState.totalAmount),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
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

class _FulfillmentSelector extends StatelessWidget {
  final _FulfillmentMethod value;
  final ValueChanged<_FulfillmentMethod> onChanged;

  const _FulfillmentSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FulfillmentTile(
          icon: Icons.local_shipping_outlined,
          title: 'Giao tận nơi',
          subtitle: 'Đơn online do thương hiệu xử lý',
          selected: value == _FulfillmentMethod.delivery,
          onTap: () => onChanged(_FulfillmentMethod.delivery),
        ),
        const SizedBox(height: AppSpacing.sm),
        _FulfillmentTile(
          icon: Icons.storefront_outlined,
          title: 'Lấy hàng tại cửa hàng',
          subtitle: 'Chọn chi nhánh còn hàng để nhận trực tiếp',
          selected: value == _FulfillmentMethod.pickup,
          onTap: () => onChanged(_FulfillmentMethod.pickup),
        ),
      ],
    );
  }
}

class _FulfillmentTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _FulfillmentTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.borderLight,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? AppColors.primary : AppColors.secondary,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? AppColors.primary : AppColors.textLightMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryFields extends StatelessWidget {
  final TextEditingController cityController;
  final TextEditingController addressController;

  const _DeliveryFields({
    required this.cityController,
    required this.addressController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppTextField(
          controller: cityController,
          labelText: 'Tỉnh/Thành phố',
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Vui lòng nhập thành phố' : null,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          controller: addressController,
          labelText: 'Địa chỉ cụ thể',
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Vui lòng nhập địa chỉ' : null,
        ),
      ],
    );
  }
}

class _PickupBranchPicker extends StatelessWidget {
  final Future<List<_PickupBranch>> branchesFuture;
  final _PickupBranch? selectedBranch;
  final ValueChanged<_PickupBranch> onSelected;

  const _PickupBranchPicker({
    required this.branchesFuture,
    required this.selectedBranch,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<List<_PickupBranch>>(
      future: branchesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Text(
            'Không tải được danh sách chi nhánh',
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.error),
          );
        }

        final branches = snapshot.data ?? const [];
        if (branches.isEmpty) {
          return Text(
            'Chưa có chi nhánh nhận hàng.',
            style: theme.textTheme.bodyMedium,
          );
        }

        return Column(
          children: branches.map((branch) {
            final selected = selectedBranch?.id == branch.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _BranchTile(
                branch: branch,
                selected: selected,
                onTap: () => onSelected(branch),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _BranchTile extends StatelessWidget {
  final _PickupBranch branch;
  final bool selected;
  final VoidCallback onTap;

  const _BranchTile({
    required this.branch,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: selected ? AppColors.success : AppColors.borderLight,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.store_outlined),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    branch.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(branch.address, style: theme.textTheme.bodySmall),
                  if (branch.phone.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(branch.phone, style: theme.textTheme.bodySmall),
                  ],
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: selected ? AppColors.success : AppColors.textLightMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _PickupBranch {
  final String id;
  final String name;
  final String address;
  final String phone;

  const _PickupBranch({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
  });
}

String _stringValue(Object? value, String fallback) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  return fallback;
}
