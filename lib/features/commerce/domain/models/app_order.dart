import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_order.freezed.dart';
part 'app_order.g.dart';

enum OrderStatus { pending, confirmed, shipping, completed, cancelled }

@freezed
abstract class AppOrder with _$AppOrder {
  const factory AppOrder({
    required String id,
    required String userId,
    @Default(OrderStatus.pending) OrderStatus status,
    required double totalAmount,
    required ShippingAddress shippingAddress,
    required String paymentMethod,
    @Default([]) List<OrderItem> items,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _AppOrder;

  factory AppOrder.fromJson(Map<String, dynamic> json) =>
      _$AppOrderFromJson(json);
}

@freezed
abstract class OrderItem with _$OrderItem {
  const factory OrderItem({
    required String productId,
    required String variantId,
    required String productName,
    required String size,
    required String color,
    required double price,
    required int quantity,
    required String imageUrl,
  }) = _OrderItem;

  factory OrderItem.fromJson(Map<String, dynamic> json) =>
      _$OrderItemFromJson(json);
}

@freezed
abstract class ShippingAddress with _$ShippingAddress {
  const factory ShippingAddress({
    required String fullName,
    required String phone,
    required String addressLine,
    required String city,
  }) = _ShippingAddress;

  factory ShippingAddress.fromJson(Map<String, dynamic> json) =>
      _$ShippingAddressFromJson(json);
}
