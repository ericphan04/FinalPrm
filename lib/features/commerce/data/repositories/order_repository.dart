import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart' hide Result;
import '../../../../core/error/app_failure.dart';
import '../../../../core/result/result.dart';
import '../../domain/models/app_order.dart';
import '../../domain/models/cart_item.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:uuid/uuid.dart';

abstract class OrderRepository {
  Future<Result<AppOrder>> createCheckout(
    String userId,
    List<CartItem> items,
    ShippingAddress address,
    String paymentMethod,
  );
  Future<Result<void>> cancelOrder(String orderId, String reason);
  Stream<List<AppOrder>> watchUserOrders(String uid);
}

class OrderRepositoryImpl implements OrderRepository {
  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;

  OrderRepositoryImpl(this._functions, this._firestore);

  @override
  Future<Result<AppOrder>> createCheckout(
    String userId,
    List<CartItem> items,
    ShippingAddress address,
    String paymentMethod,
  ) async {
    try {
      final idempotencyKey = const Uuid().v4();
      final callable = _functions.httpsCallable('createCheckout');

      final response = await callable.call({
        'items': items
            .map(
              (e) => {
                'cartItemId': e.id,
                'productId': e.productId,
                'variantId': e.variantId,
                'quantity': e.quantity,
              },
            )
            .toList(),
        'address': address.toJson(),
        'paymentMethod': paymentMethod,
        'idempotencyKey': idempotencyKey,
      });

      final data = response.data;
      final orderIds = List<String>.from(data['orderIds']);
      if (orderIds.isNotEmpty) {
        final orderDoc = await _firestore
            .collection('orders')
            .doc(orderIds.first)
            .get();
        if (orderDoc.exists) {
          final savedData = orderDoc.data()!;
          savedData['id'] = orderDoc.id;
          if (savedData['createdAt'] is Timestamp) {
            savedData['createdAt'] = (savedData['createdAt'] as Timestamp)
                .toDate()
                .toIso8601String();
          } else {
            savedData['createdAt'] = DateTime.now().toIso8601String();
          }
          if (savedData['updatedAt'] is Timestamp) {
            savedData['updatedAt'] = (savedData['updatedAt'] as Timestamp)
                .toDate()
                .toIso8601String();
          }
          return Success(AppOrder.fromJson(savedData));
        }
      }

      return Failure(
        AppFailure.serverError('Không thể lấy dữ liệu đơn hàng sau khi tạo'),
      );
    } catch (e) {
      return Failure(AppFailure.serverError('Lỗi đặt hàng: $e'));
    }
  }

  @override
  Future<Result<void>> cancelOrder(String orderId, String reason) async {
    try {
      final callable = _functions.httpsCallable('cancelOrder');
      await callable.call({'orderId': orderId, 'reason': reason});
      return const Success(null);
    } catch (e) {
      return Failure(AppFailure.serverError('Lỗi hủy đơn hàng: $e'));
    }
  }

  @override
  Stream<List<AppOrder>> watchUserOrders(String uid) {
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          final orders = snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            if (data['createdAt'] is Timestamp) {
              data['createdAt'] = (data['createdAt'] as Timestamp)
                  .toDate()
                  .toIso8601String();
            }
            if (data['updatedAt'] != null && data['updatedAt'] is Timestamp) {
              data['updatedAt'] = (data['updatedAt'] as Timestamp)
                  .toDate()
                  .toIso8601String();
            }
            return AppOrder.fromJson(data);
          }).toList();

          orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return orders;
        });
  }
}
