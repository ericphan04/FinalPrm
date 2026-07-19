import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart' hide Result;
import '../../../../core/error/app_failure.dart';
import '../../../../core/result/result.dart';
import '../../../auth/domain/models/app_user.dart';
import '../../../auth/domain/models/app_user_role.dart';
import '../../../commerce/domain/models/app_order.dart';
import '../../../commerce/domain/models/product.dart';
import '../../../seller/domain/models/seller_application.dart';
import '../../domain/models/audit_log.dart';

abstract class AdminRepository {
  Future<Result<List<SellerApplication>>> getPendingSellerApplications();
  Future<Result<void>> reviewSellerApplication(
    String appId,
    String action, {
    String? reason,
  });
  Future<Result<List<Product>>> getPendingProducts();
  Future<Result<void>> reviewProduct(
    String productId,
    String action, {
    String? reason,
  });
  Future<Result<List<AppUser>>> getAllUsers();
  Future<Result<void>> updateUserStatus(String userId, String status);
  Future<Result<List<AppOrder>>> getAllOrders();
  Future<Result<List<AuditLog>>> getAuditLogs();
  Future<Result<Map<String, dynamic>>> getSystemConfig();
  Future<Result<void>> updateSystemConfig(Map<String, dynamic> config);
}

class AdminRepositoryImpl implements AdminRepository {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  AdminRepositoryImpl(this._firestore, this._functions);

  @override
  Future<Result<List<SellerApplication>>> getPendingSellerApplications() async {
    try {
      final snapshot = await _firestore
          .collection('seller_applications')
          .orderBy('createdAt', descending: true)
          .get();
      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        if (data['createdAt'] is Timestamp) {
          data['createdAt'] = (data['createdAt'] as Timestamp)
              .toDate()
              .toIso8601String();
        }
        if (data['updatedAt'] is Timestamp) {
          data['updatedAt'] = (data['updatedAt'] as Timestamp)
              .toDate()
              .toIso8601String();
        }
        return SellerApplication.fromJson(data);
      }).toList();
      return Success(list);
    } catch (e) {
      return Failure(AppFailure.serverError('Lỗi lấy đơn đăng ký seller: $e'));
    }
  }

  @override
  Future<Result<void>> reviewSellerApplication(
    String appId,
    String action, {
    String? reason,
  }) async {
    try {
      final callable = _functions.httpsCallable('reviewSellerApplication');
      await callable.call({
        'applicationId': appId,
        'action': action,
        if (reason != null) 'reason': reason,
      });
      return const Success(null);
    } catch (e) {
      return Failure(AppFailure.serverError('Lỗi duyệt đơn seller: $e'));
    }
  }

  @override
  Future<Result<List<Product>>> getPendingProducts() async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .where('status', isEqualTo: 'pendingReview')
          .get();
      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        if (data['createdAt'] is Timestamp) {
          data['createdAt'] = (data['createdAt'] as Timestamp)
              .toDate()
              .toIso8601String();
        }
        return Product.fromJson(data);
      }).toList();
      return Success(list);
    } catch (e) {
      return Failure(
        AppFailure.serverError('Lỗi lấy danh sách sản phẩm chờ duyệt: $e'),
      );
    }
  }

  @override
  Future<Result<void>> reviewProduct(
    String productId,
    String action, {
    String? reason,
  }) async {
    try {
      final callable = _functions.httpsCallable('reviewProduct');
      await callable.call({
        'productId': productId,
        'action': action,
        if (reason != null) 'reason': reason,
      });
      return const Success(null);
    } catch (e) {
      return Failure(AppFailure.serverError('Lỗi duyệt sản phẩm: $e'));
    }
  }

  @override
  Future<Result<List<AppUser>>> getAllUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        data['uid'] = doc.id;
        // Parse roleMirror as AppUserRole
        final roleStr = data['roleMirror'] as String? ?? 'user';
        final role = AppUserRole.values.firstWhere(
          (e) => e.name == roleStr,
          orElse: () => AppUserRole.user,
        );
        return AppUser(
          uid: doc.id,
          email: data['email'] as String? ?? '',
          displayName: data['displayName'] as String? ?? 'Người dùng',
          photoUrl: data['avatarUrl'] as String? ?? '',
          role: role,
        );
      }).toList();
      return Success(list);
    } catch (e) {
      return Failure(
        AppFailure.serverError('Lỗi lấy danh sách người dùng: $e'),
      );
    }
  }

  @override
  Future<Result<void>> updateUserStatus(String userId, String status) async {
    try {
      // Direct update of status mirrors user status
      await _firestore.collection('users').doc(userId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return const Success(null);
    } catch (e) {
      return Failure(
        AppFailure.serverError('Lỗi cập nhật trạng thái người dùng: $e'),
      );
    }
  }

  @override
  Future<Result<List<AppOrder>>> getAllOrders() async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .get();
      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        if (data['createdAt'] is Timestamp) {
          data['createdAt'] = (data['createdAt'] as Timestamp)
              .toDate()
              .toIso8601String();
        }
        if (data['updatedAt'] is Timestamp) {
          data['updatedAt'] = (data['updatedAt'] as Timestamp)
              .toDate()
              .toIso8601String();
        }
        return AppOrder.fromJson(data);
      }).toList();
      return Success(list);
    } catch (e) {
      return Failure(AppFailure.serverError('Lỗi lấy danh sách đơn hàng: $e'));
    }
  }

  @override
  Future<Result<List<AuditLog>>> getAuditLogs() async {
    try {
      final snapshot = await _firestore
          .collection('auditLogs')
          .orderBy('createdAt', descending: true)
          .get();
      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        if (data['createdAt'] is Timestamp) {
          data['createdAt'] = (data['createdAt'] as Timestamp)
              .toDate()
              .toIso8601String();
        } else {
          data['createdAt'] = DateTime.now().toIso8601String();
        }
        return AuditLog.fromJson(data);
      }).toList();
      return Success(list);
    } catch (e) {
      return Failure(AppFailure.serverError('Lỗi lấy audit logs: $e'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getSystemConfig() async {
    try {
      final doc = await _firestore.collection('config').doc('system').get();
      if (doc.exists) {
        return Success(doc.data()!);
      }
      return const Success({'lowStockThreshold': 5, 'cancellationHours': 24});
    } catch (e) {
      return Failure(AppFailure.serverError('Lỗi lấy cấu hình hệ thống: $e'));
    }
  }

  @override
  Future<Result<void>> updateSystemConfig(Map<String, dynamic> config) async {
    try {
      await _firestore
          .collection('config')
          .doc('system')
          .set(config, SetOptions(merge: true));
      return const Success(null);
    } catch (e) {
      return Failure(
        AppFailure.serverError('Lỗi cập nhật cấu hình hệ thống: $e'),
      );
    }
  }
}
