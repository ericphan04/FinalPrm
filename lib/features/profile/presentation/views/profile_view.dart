import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../controllers/profile_controller.dart';
class ProfileView extends ConsumerStatefulWidget {
  const ProfileView({super.key});

  @override
  ConsumerState<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<ProfileView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Helper method to get initials for profile avatar fallback
  String _getInitials(String name) {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 400,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        await ref.read(profileControllerProvider.notifier).updateAvatar(file);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể chọn ảnh: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _onSave() {
    if (_formKey.currentState!.validate()) {
      ref
          .read(profileControllerProvider.notifier)
          .updateProfile(
            displayName: _nameController.text,
            phone: _phoneController.text,
          );
    }
  }

  void _showDiscardConfirm() {
    final state = ref.read(profileControllerProvider);
    if (_nameController.text != state.profile.displayName ||
        _phoneController.text != state.profile.phone) {
      showDialog(
        context: context,
        builder: (ctx) => ConfirmDialog(
          title: 'Hủy thay đổi?',
          content: 'Bạn có chắc chắn muốn hủy các thay đổi chưa lưu?',
          confirmText: 'Đồng ý',
          cancelText: 'Quay lại',
          isDestructive: true,
          onConfirm: () {
            _nameController.text = state.profile.displayName;
            _phoneController.text = state.profile.phone;
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileControllerProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Initialize text fields when profile data loads
    if (!state.isLoading && state.profile.uid.isNotEmpty && !_isInitialized) {
      _nameController.text = state.profile.displayName;
      _phoneController.text = state.profile.phone;
      _isInitialized = true;
    }

    // Monitor success and error messages
    ref.listen(profileControllerProvider, (previous, next) {
      if (next.isSaveSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật thông tin thành công!'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
        ref.read(profileControllerProvider.notifier).clearStatus();
      }
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
        ref.read(profileControllerProvider.notifier).clearStatus();
      }
    });

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Thông tin cá nhân'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => context.pop(),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: AppSpacing.md),
                  // Avatar Section with Edit button overlay
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary,
                              width: 3,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.shadowColor,
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            backgroundColor: isDark
                                ? AppColors.surfaceDark
                                : AppColors.primaryLight,
                            backgroundImage: state.profile.avatarUrl.isNotEmpty
                                ? (state.profile.avatarUrl.startsWith('http')
                                      ? NetworkImage(state.profile.avatarUrl)
                                      : FileImage(File(state.profile.avatarUrl))
                                            as ImageProvider)
                                : null,
                            child: state.profile.avatarUrl.isEmpty
                                ? Text(
                                    _getInitials(state.profile.displayName),
                                    style: theme.textTheme.headlineMedium
                                        ?.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 32,
                                        ),
                                  )
                                : null,
                          ),
                        ),
                        // Circular Edit Camera Icon
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    state.profile.displayName.isNotEmpty
                        ? state.profile.displayName
                        : 'Tài khoản mới',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    state.profile.email,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.textDarkMuted
                          : AppColors.textLightMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Fields Group
                  AppTextField(
                    controller: _nameController,
                    labelText: 'Họ và tên',
                    hintText: 'Nhập họ và tên của bạn',
                    prefixIcon: const Icon(
                      Icons.person_outline_rounded,
                      color: AppColors.primary,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Họ và tên không được để trống';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  AppTextField(
                    controller: _phoneController,
                    labelText: 'Số điện thoại',
                    hintText: 'Nhập số điện thoại nhận hàng',
                    keyboardType: TextInputType.phone,
                    prefixIcon: const Icon(
                      Icons.phone_iphone_rounded,
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
                    controller: TextEditingController(
                      text: state.profile.email,
                    ),
                    labelText: 'Địa chỉ Email (Không thể thay đổi)',
                    readOnly: true,
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: isDark
                          ? AppColors.textDarkMuted
                          : AppColors.textLightMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Actions Buttons
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          text: 'Hủy bỏ',
                          onPressed: _showDiscardConfirm,
                          variant: AppButtonVariant.outlined,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: AppButton(
                          text: 'Lưu thay đổi',
                          onPressed: _onSave,
                          variant: AppButtonVariant.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Footer links
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.help_outline_rounded,
                      color: AppColors.primary,
                    ),
                    title: const Text('Trợ giúp & FAQ'),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                    ),
                    onTap: () => context.push('/help'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.primary,
                    ),
                    title: const Text('Về ứng dụng'),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                    ),
                    onTap: () => context.push('/about'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.logout_rounded,
                      color: AppColors.error,
                    ),
                    title: const Text(
                      'Đăng xuất',
                      style: TextStyle(color: AppColors.error),
                    ),
                    onTap: () {
                      ref.read(authControllerProvider.notifier).signOut();
                    },
                  ),
                  const Divider(height: 1),
                ],
              ),
            ),
          ),
        ),
        if (state.isLoading)
          const LoadingView(
            message: 'Đang lưu thông tin cá nhân...',
            isOverlay: true,
          ),
      ],
    );
  }
}
