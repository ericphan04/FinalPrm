import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';

class NotificationService {
  final FirebaseFirestore _firestore;
  final FirebaseMessaging _messaging;

  NotificationService(this._firestore, this._messaging);

  Future<void> initialize(String? userId) async {
    try {
      // Request permission
      await _messaging.requestPermission(alert: true, badge: true, sound: true);

      // Get current FCM token
      final token = await _messaging.getToken();
      if (token != null && userId != null && userId.isNotEmpty) {
        await _saveTokenToDatabase(userId, token);
      }

      // Listen to token refresh
      _messaging.onTokenRefresh.listen((newToken) async {
        if (userId != null && userId.isNotEmpty) {
          await _saveTokenToDatabase(userId, newToken);
        }
      });
    } catch (e) {
      // Ignored for environments without full FCM setup
    }
  }

  Future<void> _saveTokenToDatabase(String userId, String token) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('fcm_tokens')
          .doc(token)
          .set({'updatedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      // Ignored if permissions fail (e.g., emulator baseline)
    }
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(
    FirebaseFirestore.instance,
    FirebaseMessaging.instance,
  );
});

// Riverpod Provider to auto-run FCM registration when user logs in
final notificationInitializerProvider = Provider<void>((ref) {
  final user = ref.watch(authStateProvider);
  final service = ref.read(notificationServiceProvider);
  if (user.uid.isNotEmpty) {
    service.initialize(user.uid);
  }
});
