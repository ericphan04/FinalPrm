import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../domain/models/app_user_role.dart';
import '../providers/auth_providers.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onRegister() {
    if (_formKey.currentState!.validate()) {
      ref
          .read(authControllerProvider.notifier)
          .signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            displayName: _nameController.text.trim(),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    ref.listen(authControllerProvider, (previous, next) {
      if (previous?.isLoading == true && !next.isLoading) {
        if (next.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.errorMessage!),
              backgroundColor: AppColors.error,
            ),
          );
        } else if (next.user.role != AppUserRole.guest) {
          context.go('/');
        }
      } else if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    final backgroundColor = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;
    final primaryTextColor = isDark
        ? AppColors.textDarkPrimary
        : AppColors.textLightPrimary;
    final secondaryTextColor = isDark
        ? AppColors.textDarkSecondary
        : AppColors.textLightSecondary;
    final cardColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05),
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: primaryTextColor,
                ),
              ),
              onPressed: () => context.pop(),
              tooltip: 'Quay lại',
            ),
          ),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 440),
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.4 : 0.06,
                        ),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                      width: 1,
                    ),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header Icon
                        Center(
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark ? Colors.white : AppColors.primary,
                            ),
                            child: Icon(
                              Icons.person_add_outlined,
                              size: 32,
                              color: isDark ? AppColors.primary : Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Title & Subtitle
                        Text(
                          'Tạo tài khoản mới',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: primaryTextColor,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Đăng ký để bắt đầu trải nghiệm mua sắm đẳng cấp',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: secondaryTextColor,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Input Fields
                        AppTextField(
                          controller: _nameController,
                          labelText: 'Họ và tên',
                          hintText: 'Nhập họ và tên...',
                          prefixIcon: Icon(
                            Icons.person_outline_rounded,
                            color: primaryTextColor.withValues(alpha: 0.7),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Họ và tên không được để trống';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),

                        AppTextField(
                          controller: _emailController,
                          labelText: 'Địa chỉ Email',
                          hintText: 'email@domain.com',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: primaryTextColor.withValues(alpha: 0.7),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Email không được để trống';
                            }
                            final emailRegExp = RegExp(
                              r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                            );
                            if (!emailRegExp.hasMatch(value.trim())) {
                              return 'Định dạng email không hợp lệ';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),

                        AppTextField(
                          controller: _passwordController,
                          labelText: 'Mật khẩu',
                          hintText: 'Tối thiểu 6 ký tự',
                          isPassword: true,
                          prefixIcon: Icon(
                            Icons.lock_outline_rounded,
                            color: primaryTextColor.withValues(alpha: 0.7),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Mật khẩu không được để trống';
                            }
                            if (value.length < 6) {
                              return 'Mật khẩu tối thiểu từ 6 ký tự';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),

                        AppTextField(
                          controller: _confirmPasswordController,
                          labelText: 'Xác nhận mật khẩu',
                          hintText: 'Nhập lại mật khẩu...',
                          isPassword: true,
                          prefixIcon: Icon(
                            Icons.lock_reset_rounded,
                            color: primaryTextColor.withValues(alpha: 0.7),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Vui lòng xác nhận mật khẩu';
                            }
                            if (value != _passwordController.text) {
                              return 'Mật khẩu xác nhận không khớp';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Action Button
                        AppButton(
                          text: 'ĐĂNG KÝ NGAY',
                          onPressed: _onRegister,
                          variant: AppButtonVariant.primary,
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Footer Navigation link
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'Đã có tài khoản? ',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: secondaryTextColor,
                              ),
                            ),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => context.pop(),
                              child: Text(
                                'Đăng nhập ngay',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: primaryTextColor,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (state.isLoading)
          const LoadingView(
            message: 'Đang tạo tài khoản mới...',
            isOverlay: true,
          ),
      ],
    );
  }
}
