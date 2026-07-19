import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class NotificationHistoryView extends ConsumerWidget {
  const NotificationHistoryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (user.uid.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Thông báo')),
        body: const EmptyView(
          title: 'Yêu cầu đăng nhập',
          description: 'Vui lòng đăng nhập để xem thông báo.',
          icon: Icons.notifications_off_rounded,
        ),
      );
    }

    final notificationsStream = FirebaseFirestore.instance
        .collection('notifications')
        .doc(user.uid)
        .collection('items')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Thông báo của tôi'), centerTitle: true),
      body: StreamBuilder<QuerySnapshot>(
        stream: notificationsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorView(onRetry: () {});
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const EmptyView(
              title: 'Không có thông báo',
              description: 'Hộp thư của bạn hiện đang trống.',
              icon: Icons.notifications_none_rounded,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final title = data['title'] as String? ?? 'Thông báo';
              final body = data['body'] as String? ?? '';
              final readAt = data['readAt'];
              final isRead = readAt != null;

              final timestamp = data['createdAt'] as Timestamp?;
              final timeStr = timestamp != null
                  ? DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate())
                  : '';

              return Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                color: isRead
                    ? (isDark ? AppColors.surfaceDark : Colors.white)
                    : (isDark
                          ? Colors.blueGrey.withOpacity(0.2)
                          : Colors.blue.withOpacity(0.05)),
                child: ListTile(
                  title: Text(
                    title,
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(body),
                      const SizedBox(height: 4),
                      Text(
                        timeStr,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  trailing: !isRead
                      ? const CircleAvatar(
                          radius: 5,
                          backgroundColor: AppColors.primary,
                        )
                      : null,
                  onTap: () async {
                    if (!isRead) {
                      await doc.reference.update({
                        'readAt': FieldValue.serverTimestamp(),
                      });
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
