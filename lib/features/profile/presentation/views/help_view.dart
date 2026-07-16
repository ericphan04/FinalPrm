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
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildFAQTile(
            context,
            'Tôi có thể thanh toán bằng phương thức nào?',
            'Trong phiên bản MVP 1.0 hiện tại, chúng tôi bắt buộc sử dụng phương thức Thanh toán khi nhận hàng (COD). Các hình thức thanh toán trực tuyến qua ví điện tử và ngân hàng sẽ được bổ sung ở các phiên bản tiếp theo.',
          ),
          _buildFAQTile(
            context,
            'Làm thế nào để trở thành Người Bán Hàng (Seller)?',
            'Bạn có thể đăng ký tài khoản Seller trong mục "Seller Center" trên ứng dụng. Sau khi điền thông tin và gửi hồ sơ, Quản trị viên (Admin) sẽ xét duyệt hồ sơ của bạn trong vòng 24h. Khi được phê duyệt, bạn sẽ nhận được quyền bán hàng sau khi tải lại ứng dụng.',
          ),
          _buildFAQTile(
            context,
            'Tôi có thể hủy đơn hàng đã đặt hay không?',
            'Bạn chỉ có thể tự hủy đơn hàng khi trạng thái đơn hàng hiển thị là "Chờ xác nhận" (Pending) hoặc "Đã xác nhận" (Confirmed). Sau khi đơn hàng chuyển sang trạng thái "Đang đóng gói" (Packing) hoặc "Đang giao" (Shipping), bạn sẽ không thể tự hủy trên ứng dụng mà phải liên hệ với tổng đài hỗ trợ.',
          ),
          _buildFAQTile(
            context,
            'Tôi có thể đặt hàng từ nhiều Shop khác nhau trong một đơn hàng không?',
            'Có. Giỏ hàng của bạn có thể chứa sản phẩm từ nhiều Shop khác nhau. Khi bạn tiến hành thanh toán (checkout), hệ thống backend sẽ tự động tách giỏ hàng thành các đơn hàng con riêng biệt cho từng Shop tương ứng để thuận tiện cho việc xử lý và vận chuyển.',
          ),
          _buildFAQTile(
            context,
            'Quy định về đánh giá sản phẩm như thế nào?',
            'Để đảm bảo tính khách quan, chỉ những khách hàng đã mua và nhận hàng thành công (trạng thái đơn hàng "Đã giao hàng" - Delivered) mới được quyền đánh giá sản phẩm. Mỗi sản phẩm trong đơn hàng chỉ được đánh giá duy nhất một lần.',
          ),
          
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Kênh hỗ trợ trực tiếp',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  _buildContactRow(context, Icons.phone_rounded, 'Hotline hỗ trợ', '1900 1234 (8:00 - 21:00)'),
                  const Divider(height: 16),
                  _buildContactRow(context, Icons.email_rounded, 'Email hỗ trợ', 'support@shoemarket.vn'),
                  const Divider(height: 16),
                  _buildContactRow(context, Icons.language_rounded, 'Website hỗ trợ', 'www.shoemarket.vn'),
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
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
            child: Text(
              answer,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(BuildContext context, IconData icon, String label, String value) {
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
                style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
