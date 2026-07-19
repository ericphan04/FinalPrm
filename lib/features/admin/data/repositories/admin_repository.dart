import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart' hide Result;
import 'package:firebase_auth/firebase_auth.dart';
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
  Future<Result<void>> syncAllUsersClaims();
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
      final currentAdmin = FirebaseAuth.instance.currentUser;
      final adminUid = currentAdmin?.uid ?? 'unknown';

      // 1. Get Application Doc
      final appRef = _firestore.collection('seller_applications').doc(appId);
      final appSnap = await appRef.get();
      if (!appSnap.exists) {
        return const Failure(AppFailure(code: 'not_found', message: 'Không tìm thấy hồ sơ đăng ký'));
      }
      final appData = appSnap.data()!;

      final batch = _firestore.batch();

      if (action == 'reject') {
        batch.update(appRef, {
          'status': 'rejected',
          'rejectReason': reason,
          'reviewedBy': adminUid,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        final auditRef = _firestore.collection('auditLogs').doc();
        batch.set(auditRef, {
          'actorUid': adminUid,
          'actorRole': 'admin',
          'action': 'rejectSellerApplication',
          'targetType': 'seller_application',
          'targetId': appId,
          'reason': reason ?? 'Từ chối đơn ứng tuyển',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        // action == 'approve'
        batch.update(appRef, {
          'status': 'approved',
          'reviewedBy': adminUid,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Update User Doc
        final userRef = _firestore.collection('users').doc(appId);
        batch.update(userRef, {
          'role': 'seller',
          'roleMirror': 'seller',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Set Store Doc
        final storeRef = _firestore.collection('stores').doc(appId);
        batch.set(storeRef, {
          'ownerUid': appId,
          'name': appData['storeName'] ?? 'Cửa hàng của bạn',
          'slug': 'store-$appId',
          'description': appData['description'] ?? 'Chưa có mô tả',
          'status': 'active',
          'rating': 5.0,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        final auditRef = _firestore.collection('auditLogs').doc();
        batch.set(auditRef, {
          'actorUid': adminUid,
          'actorRole': 'admin',
          'action': 'approveSellerApplication',
          'targetType': 'seller_application',
          'targetId': appId,
          'createdAt': FieldValue.serverTimestamp(),
          'reason': 'Phê duyệt tài khoản người bán thành công',
        });
      }

      await batch.commit();
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
      final currentAdmin = FirebaseAuth.instance.currentUser;
      final adminUid = currentAdmin?.uid ?? 'unknown';

      final productRef = _firestore.collection('products').doc(productId);

      String status = 'draft';
      if (action == 'approve') {
        status = 'published';
      } else if (action == 'reject') {
        status = 'rejected';
      } else if (action == 'hide') {
        status = 'draft';
      }

      final batch = _firestore.batch();
      batch.update(productRef, {
        'status': status,
        'rejectReason': action == 'reject' ? reason : null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final auditRef = _firestore.collection('auditLogs').doc();
      batch.set(auditRef, {
        'actorUid': adminUid,
        'actorRole': 'admin',
        'action': '${action}Product',
        'targetType': 'product',
        'targetId': productId,
        'reason': reason ?? 'Thao tác sản phẩm: $action',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
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
          status: data['status'] as String? ?? 'active',
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

  @override
  Future<Result<void>> syncAllUsersClaims() async {
    try {
      final callable = _functions.httpsCallable('syncAllUsersClaims');
      await callable.call();
      return const Success(null);
    } catch (e) {
      return Failure(
        AppFailure.serverError('Lỗi đồng bộ Custom Claims: $e'),
      );
    }
  }
}
