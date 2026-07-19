import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart' hide Result;
import '../../../../core/error/app_failure.dart';
import '../../../../core/result/result.dart';
import '../../domain/models/app_order.dart';
import '../../domain/models/cart_item.dart';

import 'package:firebase_auth/firebase_auth.dart';

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
      final orderRef = _firestore.collection('orders').doc();
      final total = items.fold<double>(0, (sum, item) => sum + (item.price * item.quantity));
      
      final orderData = {
        'userId': userId,
        'status': 'pending',
        'totalAmount': total,
        'shippingAddress': address.toJson(),
        'paymentMethod': paymentMethod,
        'items': items.map((e) => e.toJson()).toList(),
        'createdAt': FieldValue.serverTimestamp(),
      };
      
      await orderRef.set(orderData);
      
      final orderDoc = await orderRef.get();
      if (orderDoc.exists) {
        final savedData = orderDoc.data()!;
        savedData['id'] = orderDoc.id;
        if (savedData['createdAt'] is Timestamp) {
          savedData['createdAt'] = (savedData['createdAt'] as Timestamp).toDate().toIso8601String();
        } else {
          savedData['createdAt'] = DateTime.now().toIso8601String();
        }
        return Success(AppOrder.fromJson(savedData));
      }
      
      return Failure(AppFailure.serverError('Không thể lấy dữ liệu đơn hàng sau khi tạo'));
    } catch (e) {
      return Failure(AppFailure.serverError('Lỗi hệ thống: $e'));
    }
  }

  @override
  Future<Result<void>> cancelOrder(String orderId, String reason) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': 'cancelled',
        'cancelReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return const Success(null);
    } catch (e) {
      return Failure(AppFailure.serverError('Lỗi hệ thống: $e'));
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
