import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/loading_view.dart';
import '../providers/seller_providers.dart';
import '../controllers/seller_application_controller.dart';
import '../../domain/models/seller_application.dart';

class SellerApplyView extends ConsumerStatefulWidget {
  const SellerApplyView({super.key});

  @override
  ConsumerState<SellerApplyView> createState() => _SellerApplyViewState();
}

class _SellerApplyViewState extends ConsumerState<SellerApplyView> {
  final _formKey = GlobalKey<FormState>();
  final _storeNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void dispose() {
    _storeNameController.dispose();
    _phoneController.dispose();
    _descController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _submitApplication() {
    if (_formKey.currentState!.validate()) {
      ref
          .read(sellerApplicationControllerProvider.notifier)
          .apply(
            storeName: _storeNameController.text.trim(),
            phone: _phoneController.text.trim(),
            description: _descController.text.trim(),
            address: _addressController.text.trim(),
          )
          .then((success) {
            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Nộp đơn đăng ký thành công! Đang chờ Admin duyệt.',
                  ),
                  backgroundColor: AppColors.success,
                ),
              );
            }
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sellerApplicationControllerProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Monitor error messages
    ref.listen(sellerApplicationControllerProvider, (previous, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    Widget content;

    if (state.application == null) {
      // Form to apply
      content = SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Beautiful Header Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadowColor,
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.storefront_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Bắt đầu bán hàng cùng chúng tôi',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Mở rộng kinh doanh giày dép trực tuyến của bạn chỉ trong vài bước đơn giản.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              Text(
                'Thông tin đăng ký cửa hàng',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              AppTextField(
                controller: _storeNameController,
                labelText: 'Tên cửa hàng',
                hintText: 'Nhập tên cửa hàng của bạn',
                prefixIcon: const Icon(
                  Icons.store_rounded,
                  color: AppColors.primary,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Tên cửa hàng không được để trống';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              AppTextField(
                controller: _phoneController,
                labelText: 'Số điện thoại liên hệ',
                hintText: 'Nhập số điện thoại của bạn',
                keyboardType: TextInputType.phone,
                prefixIcon: const Icon(
                  Icons.phone_rounded,
                  color: AppColors.primary,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Số điện thoại không được để trống';
                  }
                  if (val.length < 10) {
                    return 'Số điện thoại tối thiểu phải có 10 chữ số';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              AppTextField(
                controller: _descController,
                labelText: 'Mô tả cửa hàng',
                hintText:
                    'Giới thiệu sơ lược về cửa hàng hoặc sản phẩm của bạn',
                maxLines: 3,
                prefixIcon: const Icon(
                  Icons.description_rounded,
                  color: AppColors.primary,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Mô tả cửa hàng không được để trống';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              AppTextField(
                controller: _addressController,
                labelText: 'Địa chỉ lấy hàng',
                hintText: 'Số nhà, tên đường, quận/huyện, tỉnh/thành phố',
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
                  text: 'Gửi đơn đăng ký',
                  onPressed: _submitApplication,
                  variant: AppButtonVariant.primary,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      final app = state.application!;

      if (app.status == SellerApplicationStatus.pending) {
        content = Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Beautiful animated-like card for pending status
              Container(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadowColor,
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            strokeWidth: 4,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.schedule_rounded,
                          size: 40,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Đang chờ phê duyệt',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Hồ sơ đăng ký mở cửa hàng "${app.storeName}" đã được tiếp nhận và đang được Admin xem xét. Kết quả sẽ được cập nhật trong 24h làm việc.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppColors.textDarkSecondary
                            : AppColors.textLightSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const Divider(),
                    const SizedBox(height: AppSpacing.md),
                    _buildApplicationDetailRow(
                      context,
                      'Tên shop',
                      app.storeName,
                    ),
                    _buildApplicationDetailRow(context, 'SĐT', app.phone),
                    _buildApplicationDetailRow(context, 'Địa chỉ', app.address),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              AppButton(
                text: 'Trở lại trang cá nhân',
                onPressed: () => context.pop(),
                variant: AppButtonVariant.outlined,
                width: 220,
              ),
            ],
          ),
        );
      } else if (app.status == SellerApplicationStatus.rejected) {
        content = SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadowColor,
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.cancel_rounded,
                      size: 72,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Đơn đăng ký bị từ chối',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.error.withOpacity(0.2),
                        ),
                      ),
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lý do từ chối:',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.error,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            app.rejectReason ??
                                'Hồ sơ không đạt tiêu chuẩn của sàn giao dịch giày dép. Vui lòng kiểm tra lại thông tin.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark ? Colors.red[100] : Colors.red[900],
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const Divider(),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Vui lòng chỉnh sửa thông tin bên dưới và bấm gửi lại để gửi yêu cầu phê duyệt mới.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.textDarkMuted
                            : AppColors.textLightMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              // Show editable form to re-apply
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    AppTextField(
                      controller: _storeNameController
                        ..text = _storeNameController.text.isEmpty
                            ? app.storeName
                            : _storeNameController.text,
                      labelText: 'Tên cửa hàng',
                      prefixIcon: const Icon(
                        Icons.store_rounded,
                        color: AppColors.primary,
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Tên cửa hàng không được để trống';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      controller: _phoneController
                        ..text = _phoneController.text.isEmpty
                            ? app.phone
                            : _phoneController.text,
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
                      controller: _descController
                        ..text = _descController.text.isEmpty
                            ? app.description
                            : _descController.text,
                      labelText: 'Mô tả',
                      maxLines: 3,
                      prefixIcon: const Icon(
                        Icons.description_rounded,
                        color: AppColors.primary,
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Mô tả không được để trống';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      controller: _addressController
                        ..text = _addressController.text.isEmpty
                            ? app.address
                            : _addressController.text,
                      labelText: 'Địa chỉ lấy hàng',
                      prefixIcon: const Icon(
                        Icons.location_on_rounded,
                        color: AppColors.primary,
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Địa chỉ không được để trống';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            text: 'Quay lại',
                            onPressed: () => context.pop(),
                            variant: AppButtonVariant.outlined,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: AppButton(
                            text: 'Gửi lại đơn',
                            onPressed: _submitApplication,
                            variant: AppButtonVariant.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      } else {
        // Status is approved but role hasn't refreshed or they just got approved
        content = Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  size: 80,
                  color: AppColors.success,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Chúc mừng!',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Đơn đăng ký của bạn đã được phê duyệt thành công. Vui lòng đăng nhập lại để kích hoạt Kênh Người Bán.',
                  textAlign: TextAlign.center,
                  style: TextStyle(height: 1.4),
                ),
                const SizedBox(height: AppSpacing.xxl),
                AppButton(
                  text: 'Vào kênh người bán',
                  onPressed: () => context.go('/seller/dashboard'),
                  variant: AppButtonVariant.primary,
                  width: 220,
                ),
              ],
            ),
          ),
        );
      }
    }

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Đăng ký Người bán'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => context.pop(),
            ),
          ),
          body: content,
        ),
        if (state.isLoading)
          const LoadingView(message: 'Đang xử lý đăng ký...', isOverlay: true),
      ],
    );
  }

  Widget _buildApplicationDetailRow(
    BuildContext context,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppColors.textDarkMuted
                    : AppColors.textLightMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.textDarkPrimary
                    : AppColors.textLightPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
