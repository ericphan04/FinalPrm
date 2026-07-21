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

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() {
    if (_formKey.currentState!.validate()) {
      ref
          .read(authControllerProvider.notifier)
          .signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
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
              onPressed: () => context.go('/'),
              tooltip: 'Về trang chủ',
            ),
          ),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
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
                        // Brand Icon
                        Center(
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark ? Colors.white : AppColors.primary,
                            ),
                            child: Icon(
                              Icons.shopping_bag_outlined,
                              size: 36,
                              color: isDark ? AppColors.primary : Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Title & Subtitle
                        Text(
                          'SHOE MARKET',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: primaryTextColor,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Đăng nhập để trải nghiệm mua sắm',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: secondaryTextColor,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxl),

                        // Email input
                        AppTextField(
                          controller: _emailController,
                          labelText: 'Địa chỉ email',
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
                        const SizedBox(height: AppSpacing.lg),

                        // Password input
                        AppTextField(
                          controller: _passwordController,
                          labelText: 'Mật khẩu',
                          hintText: '••••••••',
                          isPassword: true,
                          prefixIcon: Icon(
                            Icons.lock_outline_rounded,
                            color: primaryTextColor.withValues(alpha: 0.7),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Mật khẩu không được để trống';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        // Forgot password link
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => context.push('/forgot-password'),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.xs,
                              ),
                              child: Text(
                                'Quên mật khẩu?',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: primaryTextColor,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Login button
                        AppButton(
                          text: 'ĐĂNG NHẬP',
                          onPressed: _onLogin,
                          variant: AppButtonVariant.primary,
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Register footer
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'Chưa có tài khoản? ',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: secondaryTextColor,
                              ),
                            ),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => context.push('/register'),
                              child: Text(
                                'Đăng ký ngay',
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
            message: 'Đang xử lý đăng nhập...',
            isOverlay: true,
          ),
      ],
    );
  }
}
