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
  Future<Result<List<Product>>> getAllProducts();
  Future<Result<void>> importBrandProduct(
    Product product, {
    required List<Map<String, dynamic>> branchInventory,
  });
  Future<Result<void>> reviewProduct(
    String productId,
    String action, {
    String? reason,
  });
  Future<Result<List<AppUser>>> getAllUsers();
  Future<Result<void>> updateUserStatus(String userId, String status);
  Future<Result<List<AppOrder>>> getAllOrders();
  Future<Result<List<AuditLog>>> getAuditLogs();
  Future<Result<List<Map<String, dynamic>>>> getStockRequests();
  Future<Result<void>> updateStockRequestStatus(
    String requestId,
    String status,
  );
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
      return Failure(
        AppFailure.serverError('Lá»—i láº¥y Ä‘Æ¡n Ä‘Äƒng kĂ½ seller: $e'),
      );
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
        return const Failure(
          AppFailure(
            code: 'not_found',
            message: 'KhĂ´ng tĂ¬m tháº¥y há»“ sÆ¡ Ä‘Äƒng kĂ½',
          ),
        );
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
          'reason': reason ?? 'Tá»« chá»‘i Ä‘Æ¡n á»©ng tuyá»ƒn',
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
          'name': appData['storeName'] ?? 'Cá»­a hĂ ng cá»§a báº¡n',
          'slug': 'store-$appId',
          'description': appData['description'] ?? 'ChÆ°a cĂ³ mĂ´ táº£',
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
          'reason': 'PhĂª duyá»‡t tĂ i khoáº£n ngÆ°á»i bĂ¡n thĂ nh cĂ´ng',
        });
      }

      await batch.commit();
      return const Success(null);
    } catch (e) {
      return Failure(AppFailure.serverError('Lá»—i duyá»‡t Ä‘Æ¡n seller: $e'));
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
        AppFailure.serverError(
          'Lá»—i láº¥y danh sĂ¡ch sáº£n pháº©m chá» duyá»‡t: $e',
        ),
      );
    }
  }

  @override
  Future<Result<List<Product>>> getAllProducts() async {
    try {
      final snapshot = await _firestore
          .collection('products')
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
        return Product.fromJson(data);
      }).toList();
      return Success(list);
    } catch (e) {
      return Failure(
        AppFailure.serverError(
          'Lá»—i láº¥y danh sĂ¡ch táº¥t cáº£ sáº£n pháº©m: $e',
        ),
      );
    }
  }

  @override
  Future<Result<void>> importBrandProduct(
    Product product, {
    required List<Map<String, dynamic>> branchInventory,
  }) async {
    try {
      final currentAdmin = FirebaseAuth.instance.currentUser;
      final adminUid = currentAdmin?.uid ?? 'unknown';
      final productRef = _firestore.collection('products').doc(product.id);
      final auditRef = _firestore.collection('auditLogs').doc();
      final data = product.toJson();
      data.remove('id');
      data['sellerId'] = 'admin';
      data['ownerType'] = 'brand';
      data['ownerId'] = 'admin';
      data['status'] = ProductStatus.published.name;
      data['isAvailable'] = true;
      data['createdAt'] = Timestamp.fromDate(product.createdAt);
      data['updatedAt'] = FieldValue.serverTimestamp();
      data['variants'] = product.variants.map((v) => v.toJson()).toList();
      data['branchInventory'] = branchInventory;

      final batch = _firestore.batch();
      batch.set(productRef, data);
      batch.set(auditRef, {
        'actorUid': adminUid,
        'actorRole': 'admin',
        'action': 'importBrandProduct',
        'targetType': 'product',
        'targetId': product.id,
        'reason': 'Quản trị đã nhập sản phẩm thương hiệu và tồn kho chi nhánh.',
        'createdAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();
      return const Success(null);
    } catch (e) {
      return Failure(AppFailure.serverError('Khong the import san pham: $e'));
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
        'reason': reason ?? 'Thao tĂ¡c sáº£n pháº©m: $action',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      return const Success(null);
    } catch (e) {
      return Failure(AppFailure.serverError('Lá»—i duyá»‡t sáº£n pháº©m: $e'));
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
          displayName: data['displayName'] as String? ?? 'NgÆ°á»i dĂ¹ng',
          photoUrl: data['avatarUrl'] as String? ?? '',
          role: role,
          status: data['status'] as String? ?? 'active',
        );
      }).toList();
      return Success(list);
    } catch (e) {
      return Failure(
        AppFailure.serverError('Lá»—i láº¥y danh sĂ¡ch ngÆ°á»i dĂ¹ng: $e'),
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
        AppFailure.serverError(
          'Lá»—i cáº­p nháº­t tráº¡ng thĂ¡i ngÆ°á»i dĂ¹ng: $e',
        ),
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
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        data['userId'] ??= data['buyerId'] ?? '';
        data['totalAmount'] ??= _orderTotal(data);
        data['items'] ??= data['itemSnapshots'] ?? const [];
        data['createdAt'] = _dateValue(data['createdAt']);
        if (data['updatedAt'] != null) {
          data['updatedAt'] = _dateValue(data['updatedAt']);
        }
        return AppOrder.fromJson(data);
      }).toList();
      return Success(list);
    } catch (e) {
      return Failure(
        AppFailure.serverError('Lá»—i láº¥y danh sĂ¡ch Ä‘Æ¡n hĂ ng: $e'),
      );
    }
  }

  double _orderTotal(Map<String, dynamic> data) {
    final totals = data['totals'];
    if (totals is Map) {
      final total = totals['total'] ?? totals['subtotal'] ?? 0;
      if (total is num) return total.toDouble();
    }

    final items = data['items'] ?? data['itemSnapshots'];
    if (items is List) {
      return items.fold<double>(0, (total, item) {
        if (item is! Map) return total;
        final price = item['price'];
        final quantity = item['quantity'];
        return total +
            (price is num ? price.toDouble() : 0) *
                (quantity is num ? quantity.toInt() : 0);
      });
    }

    return 0;
  }

  String _dateValue(dynamic value) {
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is DateTime) return value.toIso8601String();
    if (value is String && value.isNotEmpty) return value;
    return DateTime.now().toIso8601String();
  }

  @override
  Future<Result<List<AuditLog>>> getAuditLogs() async {
    try {
      final snapshot = await _getAuditSnapshot('auditLogs');
      return Success(_auditLogsFromSnapshot(snapshot));
    } catch (_) {
      try {
        final snapshot = await _getAuditSnapshot('audit_logs');
        return Success(_auditLogsFromSnapshot(snapshot));
      } catch (_) {
        return const Success([]);
      }
    }
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _getAuditSnapshot(
    String collection,
  ) {
    return _firestore
        .collection(collection)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .get();
  }

  List<AuditLog> _auditLogsFromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      data['id'] = doc.id;
      data['actorUid'] ??= data['actorId'] ?? 'system';
      data['actorRole'] ??= 'admin';
      data['action'] ??= 'unknown';
      data['targetType'] ??= 'system';
      data['targetId'] ??= '';
      data['createdAt'] = _dateValue(data['createdAt']);
      return AuditLog.fromJson(data);
    }).toList();
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getStockRequests() async {
    try {
      final snapshot = await _firestore
          .collection('stock_requests')
          .orderBy('createdAt', descending: true)
          .get();
      final requests = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        data['createdAt'] = _dateValue(data['createdAt']);
        if (data['updatedAt'] != null) {
          data['updatedAt'] = _dateValue(data['updatedAt']);
        }
        return data;
      }).toList();
      return Success(requests);
    } catch (_) {
      return const Success([]);
    }
  }

  @override
  Future<Result<void>> updateStockRequestStatus(
    String requestId,
    String status,
  ) async {
    try {
      await _firestore.collection('stock_requests').doc(requestId).set({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return const Success(null);
    } catch (e) {
      return Failure(
        AppFailure.serverError('Không thể cập nhật yêu cầu nhập hàng: $e'),
      );
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
      return Failure(
        AppFailure.serverError('Lá»—i láº¥y cáº¥u hĂ¬nh há»‡ thá»‘ng: $e'),
      );
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
        AppFailure.serverError(
          'Lá»—i cáº­p nháº­t cáº¥u hĂ¬nh há»‡ thá»‘ng: $e',
        ),
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
        AppFailure.serverError('Lá»—i Ä‘á»“ng bá»™ Custom Claims: $e'),
      );
    }
  }
}
