import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class HelpView extends StatelessWidget {
  const HelpView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trợ giúp & FAQ'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'Các câu hỏi thường gặp',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildFAQTile(
            context,
            'Tôi có thể thanh toán bằng phương thức nào?',
            'Bạn có thể thanh toán khi nhận hàng hoặc chọn lấy hàng tại cửa hàng. Khi chọn lấy tại cửa hàng, hệ thống sẽ ghi nhận chi nhánh nhận hàng trong đơn.',
          ),
          _buildFAQTile(
            context,
            'Chi nhánh hoạt động như thế nào?',
            'Chi nhánh là tài khoản nội bộ của công ty. Chi nhánh theo dõi tồn kho được phân bổ và gửi yêu cầu bổ sung hàng cho admin khi cần.',
          ),
          _buildFAQTile(
            context,
            'Tôi có thể hủy đơn hàng đã đặt hay không?',
            'Bạn chỉ có thể tự hủy đơn hàng khi đơn đang ở trạng thái chờ xác nhận. Nếu đơn đã được xử lý hoặc đang giao, vui lòng liên hệ bộ phận hỗ trợ.',
          ),
          _buildFAQTile(
            context,
            'Đơn online do bên nào xử lý?',
            'Đơn online thuộc về thương hiệu và được admin quản lý tập trung. Tồn kho theo chi nhánh giúp khách biết nơi còn hàng và chọn điểm lấy hàng phù hợp.',
          ),
          _buildFAQTile(
            context,
            'Tồn kho chi nhánh được hiển thị ra sao?',
            'Mỗi sản phẩm hiển thị tồn kho theo chi nhánh để khách biết còn hàng hay đã hết hàng. Số lượng có thể thay đổi sau khi chi nhánh cập nhật hoặc admin phân bổ thêm hàng.',
          ),

          const SizedBox(height: AppSpacing.xl),
          Text(
            'Kênh hỗ trợ trực tiếp',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  _buildContactRow(
                    context,
                    Icons.phone_rounded,
                    'Hotline hỗ trợ',
                    '1900 1234 (8:00 - 21:00)',
                  ),
                  const Divider(height: 16),
                  _buildContactRow(
                    context,
                    Icons.email_rounded,
                    'Email hỗ trợ',
                    'support@shoemarket.vn',
                  ),
                  const Divider(height: 16),
                  _buildContactRow(
                    context,
                    Icons.language_rounded,
                    'Website hỗ trợ',
                    'www.shoemarket.vn',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQTile(BuildContext context, String question, String answer) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ExpansionTile(
        shape: const Border(), // Removes default border highlights
        iconColor: AppColors.primary,
        title: Text(
          question,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Text(
              answer,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors.textDarkSecondary
                    : AppColors.textLightSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(value, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}
