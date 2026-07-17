import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_button.dart';

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmText;
  final String cancelText;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final bool isDestructive;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmText = 'Xác nhận',
    this.cancelText = 'Hủy',
    required this.onConfirm,
    this.onCancel,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      title: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: isDestructive
              ? AppColors.error
              : (isDark
                    ? AppColors.textDarkPrimary
                    : AppColors.textLightPrimary),
        ),
      ),
      content: Text(
        content,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: isDark
              ? AppColors.textDarkSecondary
              : AppColors.textLightSecondary,
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: AppButton(
                text: cancelText,
                onPressed: () {
                  if (onCancel != null) {
                    onCancel!();
                  } else {
                    Navigator.of(context).pop();
                  }
                },
                variant: AppButtonVariant.outlined,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppButton(
                text: confirmText,
                onPressed: () {
                  Navigator.of(context).pop();
                  onConfirm();
                },
                variant: AppButtonVariant.primary,
                // Highlight danger actions in red
                height: AppSpacing.minTouchTarget,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
