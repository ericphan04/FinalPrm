import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../auth/domain/models/app_user_role.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  String _getInitials(String name) {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (user.role == AppUserRole.guest) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_outline_rounded, size: 80, color: isDark ? Colors.white54 : Colors.black54),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Become a Member',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Sign in for free delivery, saving favorites,\nand checking out faster.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton(
                onPressed: () => context.push('/login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : Colors.black,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('Join Us / Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xxl),
              // Avatar
              CircleAvatar(
                radius: 50,
                backgroundColor: isDark ? AppColors.surfaceDark : Colors.grey[200],
                backgroundImage: user.photoUrl.isNotEmpty
                    ? NetworkImage(user.photoUrl)
                    : null,
                child: user.photoUrl.isEmpty
                    ? Text(
                        _getInitials(user.displayName),
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.grey),
                      )
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              // Name
              Text(
                user.displayName.isNotEmpty ? user.displayName : 'Người dùng mới',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.md),
              // Edit Profile Button
              OutlinedButton(
                onPressed: () => context.push('/profile'), // Dẫn đến màn hình Edit Profile cũ
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? Colors.white : Colors.black,
                  side: BorderSide(color: isDark ? Colors.white38 : Colors.black26),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: AppSpacing.xxl),
              // Action Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionItem(context, Icons.shopping_bag_outlined, 'Orders', () => context.push('/orders')),
                  _buildActionItem(context, Icons.favorite_border_rounded, 'Favorites', () {}),
                  _buildActionItem(context, Icons.settings_outlined, 'Settings', () {}),
                ],
              ),
              const Spacer(),
              // Logout Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ref.read(authControllerProvider.notifier).signOut();
                  },
                  icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                  label: const Text(
                    'Log Out',
                    style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
              ),
              const SizedBox(height: 120), // Khoảng trống để không bị đè bởi Floating Navigation Bar
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionItem(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Icon(icon, size: 28, color: isDark ? Colors.white : Colors.black),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
