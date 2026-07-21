import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart' hide Result;
import 'package:uuid/uuid.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/result/result.dart';
import '../../domain/models/app_order.dart';
import '../../domain/models/cart_item.dart';

abstract class OrderRepository {
  Future<Result<AppOrder>> createCheckout(
    String userId,
    List<CartItem> items,
    ShippingAddress address,
    String paymentMethod, {
    String fulfillmentMethod = 'delivery',
    String? pickupStoreId,
    String? pickupStoreName,
    String? pickupAddress,
  });

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
    String paymentMethod, {
    String fulfillmentMethod = 'delivery',
    String? pickupStoreId,
    String? pickupStoreName,
    String? pickupAddress,
  }) async {
    try {
      final order = await _createCheckoutWithFunction(
        userId,
        items,
        address,
        paymentMethod,
        fulfillmentMethod: fulfillmentMethod,
        pickupStoreId: pickupStoreId,
        pickupStoreName: pickupStoreName,
        pickupAddress: pickupAddress,
      );
      return Success(order);
    } catch (_) {
      try {
        final order = await _createCheckoutDirectly(
          userId,
          items,
          address,
          paymentMethod,
          fulfillmentMethod: fulfillmentMethod,
          pickupStoreId: pickupStoreId,
          pickupStoreName: pickupStoreName,
          pickupAddress: pickupAddress,
        );
        return Success(order);
      } catch (_) {
        return Failure(
          AppFailure.serverError('Khong the tao don hang. Vui long thu lai.'),
        );
      }
    }
  }

  Future<AppOrder> _createCheckoutWithFunction(
    String userId,
    List<CartItem> items,
    ShippingAddress address,
    String paymentMethod, {
    required String fulfillmentMethod,
    String? pickupStoreId,
    String? pickupStoreName,
    String? pickupAddress,
  }) async {
    final idempotencyKey = const Uuid().v4();
    final callable = _functions.httpsCallable('createCheckout');

    final response = await callable
        .call({
          'items': items
              .map(
                (item) => {
                  'cartItemId': item.id,
                  'productId': item.productId,
                  'variantId': item.variantId,
                  'quantity': item.quantity,
                },
              )
              .toList(),
          'address': address.toJson(),
          'paymentMethod': paymentMethod,
          'salesChannel': 'online',
          'ownerType': 'brand',
          'ownerId': 'admin',
          'fulfillmentMethod': fulfillmentMethod,
          'pickupStoreId': pickupStoreId,
          'pickupStoreName': pickupStoreName,
          'pickupAddress': pickupAddress,
          'idempotencyKey': idempotencyKey,
        })
        .timeout(const Duration(seconds: 12));

    final data = response.data as Map;
    final orderIds = List<String>.from(data['orderIds'] ?? const []);
    if (orderIds.isEmpty) {
      throw StateError('Checkout did not return any order id.');
    }

    final orderDoc = await _firestore
        .collection('orders')
        .doc(orderIds.first)
        .get()
        .timeout(const Duration(seconds: 8));
    if (!orderDoc.exists) {
      throw StateError('Created order was not found.');
    }

    await _ensureOrderCompatibility(
      orderDoc,
      userId,
      fulfillmentMethod: fulfillmentMethod,
    );
    final refreshedDoc = await orderDoc.reference.get();
    return _orderFromFirestore(refreshedDoc);
  }

  Future<AppOrder> _createCheckoutDirectly(
    String userId,
    List<CartItem> items,
    ShippingAddress address,
    String paymentMethod, {
    required String fulfillmentMethod,
    String? pickupStoreId,
    String? pickupStoreName,
    String? pickupAddress,
  }) async {
    final orderRef = _firestore.collection('orders').doc();
    final now = Timestamp.now();
    final orderItems = items
        .map(
          (item) => {
            'productId': item.productId,
            'variantId': item.variantId,
            'productName': item.productName,
            'size': item.size,
            'color': item.color,
            'price': item.price,
            'quantity': item.quantity,
            'imageUrl': item.imageUrl,
          },
        )
        .toList();
    final totalAmount = items.fold<double>(
      0,
      (total, item) => total + item.price * item.quantity,
    );

    await orderRef.set({
      'userId': userId,
      'buyerId': userId,
      'status': 'pending',
      'totalAmount': totalAmount,
      'totals': {'subtotal': totalAmount, 'shipping': 0, 'total': totalAmount},
      'shippingAddress': address.toJson(),
      'paymentMethod': paymentMethod,
      'salesChannel': 'online',
      'ownerType': 'brand',
      'ownerId': 'admin',
      'fulfillmentMethod': fulfillmentMethod,
      'pickupStoreId': pickupStoreId,
      'pickupStoreName': pickupStoreName,
      'pickupAddress': pickupAddress,
      'items': orderItems,
      'itemSnapshots': orderItems,
      'createdAt': now,
      'updatedAt': now,
    });

    final savedDoc = await orderRef.get();
    return _orderFromFirestore(savedDoc);
  }

  Future<void> _ensureOrderCompatibility(
    DocumentSnapshot<Map<String, dynamic>> doc,
    String userId, {
    String fulfillmentMethod = 'delivery',
  }) async {
    final data = doc.data() ?? {};
    final update = <String, dynamic>{};

    update['userId'] = data['userId'] ?? data['buyerId'] ?? userId;
    update['totalAmount'] = data['totalAmount'] ?? _totalFromData(data);
    update['items'] = data['items'] ?? data['itemSnapshots'] ?? const [];
    update['salesChannel'] = data['salesChannel'] ?? 'online';
    update['ownerType'] = data['ownerType'] ?? 'brand';
    update['ownerId'] = data['ownerId'] ?? 'admin';
    update['fulfillmentMethod'] =
        data['fulfillmentMethod'] ?? fulfillmentMethod;

    await doc.reference.set(update, SetOptions(merge: true));
  }

  AppOrder _orderFromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = Map<String, dynamic>.from(doc.data() ?? {});
    data['id'] = doc.id;
    data['userId'] ??= data['buyerId'] ?? '';
    data['totalAmount'] ??= _totalFromData(data);
    data['items'] ??= data['itemSnapshots'] ?? const [];
    data['createdAt'] = _dateValue(data['createdAt']);
    if (data['updatedAt'] != null) {
      data['updatedAt'] = _dateValue(data['updatedAt']);
    }
    return AppOrder.fromJson(data);
  }

  double _totalFromData(Map<String, dynamic> data) {
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
  Future<Result<void>> cancelOrder(String orderId, String reason) async {
    try {
      final callable = _functions.httpsCallable('cancelOrder');
      await callable.call({'orderId': orderId, 'reason': reason});
      return const Success(null);
    } catch (_) {
      try {
        await _firestore.collection('orders').doc(orderId).set({
          'status': 'cancelled',
          'cancelReason': reason,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        return const Success(null);
      } catch (_) {
        return Failure(
          AppFailure.serverError('Khong the huy don hang. Vui long thu lai.'),
        );
      }
    }
  }

  @override
  Stream<List<AppOrder>> watchUserOrders(String uid) {
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          final orders = snapshot.docs.map(_orderFromFirestore).toList();
          orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return orders;
        });
  }
}
