import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

enum AppButtonVariant { primary, secondary, outlined, text }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool isDisabled;
  final Widget? icon;
  final Widget? trailingIcon;
  final double? width;
  final double height;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.trailingIcon,
    this.width,
    this.height = AppSpacing.minTouchTarget, // Enforces 48dp touch target
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bool enabled = onPressed != null && !isLoading && !isDisabled;

    // Resolve Button Styles based on variant
    ButtonStyle buttonStyle;
    switch (variant) {
      case AppButtonVariant.primary:
        buttonStyle = ElevatedButton.styleFrom(
          backgroundColor: isDark ? Colors.white : AppColors.primary,
          foregroundColor: isDark ? AppColors.primary : Colors.white,
          disabledBackgroundColor: isDark
              ? AppColors.surfaceDark
              : AppColors.borderLight,
          disabledForegroundColor: isDark
              ? AppColors.textDarkMuted
              : AppColors.textLightMuted,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
        );
        break;
      case AppButtonVariant.secondary:
        buttonStyle = ElevatedButton.styleFrom(
          backgroundColor: isDark
              ? AppColors.surfaceDark
              : AppColors.primaryLight,
          foregroundColor: isDark
              ? AppColors.textDarkPrimary
              : AppColors.primary,
          disabledBackgroundColor: isDark
              ? AppColors.surfaceDark.withValues(alpha: 0.5)
              : AppColors.borderLight.withValues(alpha: 0.5),
          disabledForegroundColor: isDark
              ? AppColors.textDarkMuted
              : AppColors.textLightMuted,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            side: BorderSide(
              color: isDark
                  ? AppColors.borderDark
                  : AppColors.primary.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
        );
        break;
      case AppButtonVariant.outlined:
        buttonStyle = OutlinedButton.styleFrom(
          foregroundColor: isDark
              ? AppColors.textDarkPrimary
              : AppColors.secondary,
          side: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1.5,
          ),
          disabledForegroundColor: isDark
              ? AppColors.textDarkMuted
              : AppColors.textLightMuted,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        );
        break;
      case AppButtonVariant.text:
        buttonStyle = TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          disabledForegroundColor: isDark
              ? AppColors.textDarkMuted
              : AppColors.textLightMuted,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        );
        break;
    }

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null && !isLoading) ...[
          icon!,
          const SizedBox(width: AppSpacing.xs),
        ],
        if (isLoading)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                variant == AppButtonVariant.primary
                    ? (isDark ? AppColors.primary : Colors.white)
                    : (isDark ? Colors.white : AppColors.primary),
              ),
            ),
          )
        else
          Text(
            text,
            style: theme.textTheme.labelLarge?.copyWith(
              color: enabled
                  ? (variant == AppButtonVariant.primary
                        ? (isDark ? AppColors.primary : Colors.white)
                        : (variant == AppButtonVariant.text
                              ? (isDark ? Colors.white : AppColors.primary)
                              : theme.colorScheme.onSurface))
                  : (isDark
                        ? AppColors.textDarkMuted
                        : AppColors.textLightMuted),
            ),
          ),
        if (trailingIcon != null && !isLoading) ...[
          const SizedBox(width: AppSpacing.xs),
          trailingIcon!,
        ],
      ],
    );

    return SizedBox(
      width: width,
      height: height,
      child: variant == AppButtonVariant.outlined
          ? OutlinedButton(
              onPressed: enabled ? onPressed : null,
              style: buttonStyle,
              child: content,
            )
          : variant == AppButtonVariant.text
          ? TextButton(
              onPressed: enabled ? onPressed : null,
              style: buttonStyle,
              child: content,
            )
          : ElevatedButton(
              onPressed: enabled ? onPressed : null,
              style: buttonStyle,
              child: content,
            ),
    );
  }
}
