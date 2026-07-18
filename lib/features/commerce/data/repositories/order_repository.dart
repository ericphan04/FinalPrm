import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart' hide Result;
import '../../../../core/error/app_failure.dart';
import '../../../../core/result/result.dart';
import '../../domain/models/app_order.dart';
import '../../domain/models/cart_item.dart';

abstract class OrderRepository {
  Future<Result<AppOrder>> createCheckout(
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
    List<CartItem> items,
    ShippingAddress address,
    String paymentMethod,
  ) async {
    try {
      final callable = _functions.httpsCallable('createCheckout');
      final response = await callable.call({
        'items': items.map((e) => e.toJson()).toList(),
        'shippingAddress': address.toJson(),
        'paymentMethod': paymentMethod,
      });

      final data = response.data as Map<String, dynamic>;

      // Assumes function returns the created order data or ID
      if (data.containsKey('orderId')) {
        // Fetch the created order from firestore to return
        final orderDoc = await _firestore
            .collection('orders')
            .doc(data['orderId'])
            .get();
        if (orderDoc.exists) {
          final orderData = orderDoc.data()!;
          orderData['id'] = orderDoc.id;
          if (orderData['createdAt'] is Timestamp) {
            orderData['createdAt'] = (orderData['createdAt'] as Timestamp)
                .toDate()
                .toIso8601String();
          }
          return Success(AppOrder.fromJson(orderData));
        }
      }

      return Failure(
        AppFailure.serverError(
          'Không thể tạo đơn hàng, định dạng trả về không hợp lệ',
        ),
      );
    } on FirebaseFunctionsException catch (e) {
      // Map functions errors to AppFailure
      if (e.code == 'out-of-stock') {
        return Failure(AppFailure.conflict('Sản phẩm đã hết hàng'));
      }
      return Failure(AppFailure.serverError(e.message ?? 'Lỗi thanh toán'));
    } catch (e) {
      return Failure(AppFailure.serverError('Lỗi hệ thống: $e'));
    }
  }

  @override
  Future<Result<void>> cancelOrder(String orderId, String reason) async {
    try {
      final callable = _functions.httpsCallable('cancelOrder');
      await callable.call({'orderId': orderId, 'reason': reason});
      return const Success(null);
    } on FirebaseFunctionsException catch (e) {
      return Failure(AppFailure.serverError(e.message ?? 'Lỗi hủy đơn'));
    } catch (e) {
      return Failure(AppFailure.serverError('Lỗi hệ thống: $e'));
    }
  }

  @override
  Stream<List<AppOrder>> watchUserOrders(String uid) {
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
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
        });
  }
}
