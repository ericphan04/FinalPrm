import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Theme imports
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_spacing.dart';

// Shared widget imports
import 'core/widgets/app_button.dart';
import 'core/widgets/app_text_field.dart';
import 'core/widgets/product_card_skeleton.dart';
import 'core/widgets/loading_view.dart';
import 'core/widgets/empty_view.dart';
import 'core/widgets/error_view.dart';
import 'core/widgets/confirm_dialog.dart';

// Profile imports
import 'features/profile/presentation/views/profile_view.dart';
import 'features/profile/presentation/views/about_view.dart';
import 'features/profile/presentation/views/help_view.dart';

// Riverpod provider to manage theme switching globally in this demo
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    // GoRouter configuration linking our routes
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const ShowroomScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileView(),
        ),
        GoRoute(
          path: '/about',
          builder: (context, state) => const AboutView(),
        ),
        GoRoute(
          path: '/help',
          builder: (context, state) => const HelpView(),
        ),
      ],
    );

    return MaterialApp.router(
      title: 'Shoe Market UI Showroom',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

class ShowroomScreen extends ConsumerWidget {
  const ShowroomScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('UI Components Showroom'),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
            tooltip: 'Đổi giao diện',
            onPressed: () {
              ref.read(themeModeProvider.notifier).state =
                  isDark ? ThemeMode.light : ThemeMode.dark;
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Go to Profile screen card
            Card(
              color: isDark ? AppColors.surfaceDark : AppColors.primaryLight,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    const Icon(Icons.person_pin_rounded, size: 48, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Trang Cá Nhân & Support',
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Nhấn để xem Profile, FAQ, và About screens.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    AppButton(
                      text: 'Xem',
                      onPressed: () => context.push('/profile'),
                      variant: AppButtonVariant.primary,
                      height: 40,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Section Typography
            _buildSectionHeader(context, '1. Typography (Cỡ chữ)'),
            _buildShowcaseCard(
              context,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Headline Large (H1)', style: theme.textTheme.headlineLarge),
                  const SizedBox(height: AppSpacing.xxs),
                  Text('Headline Medium (H2)', style: theme.textTheme.headlineMedium),
                  const SizedBox(height: AppSpacing.xxs),
                  Text('Title Large (H3)', style: theme.textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.xxs),
                  Text('Body Large (16px)', style: theme.textTheme.bodyLarge),
                  const SizedBox(height: AppSpacing.xxs),
                  Text('Body Medium (14px)', style: theme.textTheme.bodyMedium),
                  const SizedBox(height: AppSpacing.xxs),
                  Text('Body Small (12px)', style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Section Buttons
            _buildSectionHeader(context, '2. Buttons (Nút bấm)'),
            _buildShowcaseCard(
              context,
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  AppButton(
                    text: 'Primary Button',
                    onPressed: () {},
                    variant: AppButtonVariant.primary,
                  ),
                  AppButton(
                    text: 'Secondary Button',
                    onPressed: () {},
                    variant: AppButtonVariant.secondary,
                  ),
                  AppButton(
                    text: 'Outlined Button',
                    onPressed: () {},
                    variant: AppButtonVariant.outlined,
                  ),
                  AppButton(
                    text: 'Text Button',
                    onPressed: () {},
                    variant: AppButtonVariant.text,
                  ),
                  AppButton(
                    text: 'Loading State',
                    onPressed: () {},
                    isLoading: true,
                  ),
                  AppButton(
                    text: 'Disabled Button',
                    onPressed: null,
                  ),
                  AppButton(
                    text: 'With Icon',
                    onPressed: () {},
                    icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Section TextFields
            _buildSectionHeader(context, '3. TextFields (Trường nhập liệu)'),
            _buildShowcaseCard(
              context,
              Column(
                children: [
                  const AppTextField(
                    labelText: 'Họ và tên (Mặc định)',
                    hintText: 'Nhập họ và tên...',
                    prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.primary),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const AppTextField(
                    labelText: 'Mật khẩu (Ẩn/Hiện)',
                    hintText: 'Nhập mật khẩu...',
                    isPassword: true,
                    prefixIcon: Icon(Icons.lock_outline_rounded, color: AppColors.primary),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    labelText: 'Trường có lỗi',
                    hintText: 'Trường nhập liệu lỗi...',
                    errorText: 'Thông tin này bắt buộc phải nhập',
                    prefixIcon: const Icon(Icons.warning_amber_rounded, color: AppColors.error),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Section Feedback Dialog & Overlay
            _buildSectionHeader(context, '4. Dialog & Overlay'),
            _buildShowcaseCard(
              context,
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  AppButton(
                    text: 'Show Confirm Dialog',
                    variant: AppButtonVariant.outlined,
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => ConfirmDialog(
                          title: 'Xác nhận xóa giỏ hàng?',
                          content: 'Tất cả sản phẩm trong giỏ hàng hiện tại sẽ bị xóa sạch khỏi bộ nhớ.',
                          confirmText: 'Đồng ý',
                          cancelText: 'Hủy bỏ',
                          isDestructive: true,
                          onConfirm: () {},
                        ),
                      );
                    },
                  ),
                  AppButton(
                    text: 'Show Loading Overlay (3s)',
                    variant: AppButtonVariant.outlined,
                    onPressed: () async {
                      // Trigger temporary full-screen loading overlay
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (ctx) => const LoadingView(
                          message: 'Đang tải thông tin mẫu...',
                          isOverlay: true,
                        ),
                      );
                      await Future.delayed(const Duration(seconds: 3));
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Section Product Skeleton
            _buildSectionHeader(context, '5. Product Card Skeletons (Hiệu ứng Shimmer)'),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 0.65,
              ),
              itemCount: 2,
              itemBuilder: (context, index) => const ProductCardSkeleton(),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Section Empty/Error Fallbacks
            _buildSectionHeader(context, '6. Fallback Screens (Màn hình thông báo)'),
            _buildShowcaseCard(
              context,
              Column(
                children: [
                  AppButton(
                    text: 'Xem màn Empty (Giỏ hàng trống)',
                    width: double.infinity,
                    variant: AppButtonVariant.outlined,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (ctx) => Scaffold(
                            appBar: AppBar(title: const Text('Giỏ hàng')),
                            body: const EmptyView(
                              title: 'Giỏ hàng của bạn đang trống',
                              description: 'Hãy dạo quanh cửa hàng và chọn những đôi giày ưng ý nhất nhé!',
                              icon: Icons.shopping_cart_outlined,
                              actionText: 'Mua sắm ngay',
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    text: 'Xem màn Error (Lỗi kết nối)',
                    width: double.infinity,
                    variant: AppButtonVariant.outlined,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (ctx) => Scaffold(
                            appBar: AppBar(title: const Text('Danh sách đơn hàng')),
                            body: ErrorView(
                              onRetry: () => Navigator.pop(ctx),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm, top: AppSpacing.sm),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
      ),
    );
  }

  Widget _buildShowcaseCard(BuildContext context, Widget child) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        ),
      ),
      child: child,
    );
  }
}
