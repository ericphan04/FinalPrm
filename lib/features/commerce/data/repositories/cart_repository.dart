import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/error/app_failure.dart';
import '../../../../core/result/result.dart';
import '../../domain/models/cart_item.dart';

abstract class CartRepository {
  Future<Result<List<CartItem>>> getCartItems(String? uid);
  Future<Result<void>> addToCart(String? uid, CartItem item);
  Future<Result<void>> updateQuantity(String? uid, String itemId, int quantity);
  Future<Result<void>> removeFromCart(String? uid, String itemId);
  Future<Result<void>> clearCart(String? uid);
  Future<Result<void>> mergeGuestCart(String uid);
}

class CartRepositoryImpl implements CartRepository {
  final FirebaseFirestore _firestore;
  final SharedPreferences _prefs;
  static const String _guestCartKey = 'guest_cart';

  CartRepositoryImpl(this._firestore, this._prefs);

  @override
  Future<Result<List<CartItem>>> getCartItems(String? uid) async {
    try {
      if (uid == null) {
        // Guest Cart
        final String? cartStr = _prefs.getString(_guestCartKey);
        if (cartStr == null) return const Success([]);
        final List<dynamic> jsonList = jsonDecode(cartStr);
        final items = jsonList.map((e) => CartItem.fromJson(e)).toList();
        return Success(items);
      } else {
        // User Cart
        final snapshot = await _firestore
            .collection('users')
            .doc(uid)
            .collection('cart')
            .get();
        final items = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          if (data['addedAt'] is Timestamp) {
            data['addedAt'] = (data['addedAt'] as Timestamp)
                .toDate()
                .toIso8601String();
          }
          return CartItem.fromJson(data);
        }).toList();
        return Success(items);
      }
    } catch (e) {
      return Failure(AppFailure.serverError('Lỗi lấy giỏ hàng: $e'));
    }
  }

  @override
  Future<Result<void>> addToCart(String? uid, CartItem item) async {
    try {
      if (uid == null) {
        final currentResult = await getCartItems(null);
        if (currentResult is Success<List<CartItem>>) {
          final items = List<CartItem>.from(currentResult.data);
          final existingIndex = items.indexWhere(
            (i) => i.variantId == item.variantId,
          );
          if (existingIndex >= 0) {
            items[existingIndex] = items[existingIndex].copyWith(
              quantity: items[existingIndex].quantity + item.quantity,
            );
          } else {
            items.add(item);
          }
          await _prefs.setString(
            _guestCartKey,
            jsonEncode(items.map((e) => e.toJson()).toList()),
          );
        }
      } else {
        final coll = _firestore.collection('users').doc(uid).collection('cart');
        final query = await coll
            .where('variantId', isEqualTo: item.variantId)
            .get();
        if (query.docs.isNotEmpty) {
          final doc = query.docs.first;
          await doc.reference.update({
            'quantity': FieldValue.increment(item.quantity),
          });
        } else {
          final data = item.toJson();
          data.remove('id');
          data['addedAt'] = FieldValue.serverTimestamp();
          await coll.add(data);
        }
      }
      return const Success(null);
    } catch (e) {
      return Failure(AppFailure.serverError('Lỗi thêm vào giỏ hàng: $e'));
    }
  }

  @override
  Future<Result<void>> updateQuantity(
    String? uid,
    String itemId,
    int quantity,
  ) async {
    try {
      if (uid == null) {
        final currentResult = await getCartItems(null);
        if (currentResult is Success<List<CartItem>>) {
          final items = List<CartItem>.from(currentResult.data);
          final index = items.indexWhere((i) => i.id == itemId);
          if (index >= 0) {
            items[index] = items[index].copyWith(quantity: quantity);
            await _prefs.setString(
              _guestCartKey,
              jsonEncode(items.map((e) => e.toJson()).toList()),
            );
          }
        }
      } else {
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('cart')
            .doc(itemId)
            .update({'quantity': quantity});
      }
      return const Success(null);
    } catch (e) {
      return Failure(AppFailure.serverError('Lỗi cập nhật số lượng: $e'));
    }
  }

  @override
  Future<Result<void>> removeFromCart(String? uid, String itemId) async {
    try {
      if (uid == null) {
        final currentResult = await getCartItems(null);
        if (currentResult is Success<List<CartItem>>) {
          final items = List<CartItem>.from(currentResult.data)
            ..removeWhere((i) => i.id == itemId);
          await _prefs.setString(
            _guestCartKey,
            jsonEncode(items.map((e) => e.toJson()).toList()),
          );
        }
      } else {
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('cart')
            .doc(itemId)
            .delete();
      }
      return const Success(null);
    } catch (e) {
      return Failure(AppFailure.serverError('Lỗi xóa sản phẩm khỏi giỏ: $e'));
    }
  }

  @override
  Future<Result<void>> clearCart(String? uid) async {
    try {
      if (uid == null) {
        await _prefs.remove(_guestCartKey);
      } else {
        final docs = await _firestore
            .collection('users')
            .doc(uid)
            .collection('cart')
            .get();
        final batch = _firestore.batch();
        for (var doc in docs.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
      return const Success(null);
    } catch (e) {
      return Failure(AppFailure.serverError('Lỗi xóa giỏ hàng: $e'));
    }
  }

  @override
  Future<Result<void>> mergeGuestCart(String uid) async {
    try {
      final guestResult = await getCartItems(null);
      if (guestResult is Success<List<CartItem>> &&
          guestResult.data.isNotEmpty) {
        for (var item in guestResult.data) {
          await addToCart(uid, item);
        }
        await clearCart(null); // Xóa giỏ guest sau khi merge
      }
      return const Success(null);
    } catch (e) {
      return Failure(AppFailure.serverError('Lỗi đồng bộ giỏ hàng: $e'));
    }
  }
}
