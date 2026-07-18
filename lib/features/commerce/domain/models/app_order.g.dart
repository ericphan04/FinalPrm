// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppOrder _$AppOrderFromJson(Map<String, dynamic> json) => _AppOrder(
  id: json['id'] as String,
  userId: json['userId'] as String,
  status:
      $enumDecodeNullable(_$OrderStatusEnumMap, json['status']) ??
      OrderStatus.pending,
  totalAmount: (json['totalAmount'] as num).toDouble(),
  shippingAddress: ShippingAddress.fromJson(
    json['shippingAddress'] as Map<String, dynamic>,
  ),
  paymentMethod: json['paymentMethod'] as String,
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$AppOrderToJson(_AppOrder instance) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'status': _$OrderStatusEnumMap[instance.status]!,
  'totalAmount': instance.totalAmount,
  'shippingAddress': instance.shippingAddress,
  'paymentMethod': instance.paymentMethod,
  'items': instance.items,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};

const _$OrderStatusEnumMap = {
  OrderStatus.pending: 'pending',
  OrderStatus.confirmed: 'confirmed',
  OrderStatus.shipping: 'shipping',
  OrderStatus.completed: 'completed',
  OrderStatus.cancelled: 'cancelled',
};

_OrderItem _$OrderItemFromJson(Map<String, dynamic> json) => _OrderItem(
  productId: json['productId'] as String,
  variantId: json['variantId'] as String,
  productName: json['productName'] as String,
  size: json['size'] as String,
  color: json['color'] as String,
  price: (json['price'] as num).toDouble(),
  quantity: (json['quantity'] as num).toInt(),
  imageUrl: json['imageUrl'] as String,
);

Map<String, dynamic> _$OrderItemToJson(_OrderItem instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'variantId': instance.variantId,
      'productName': instance.productName,
      'size': instance.size,
      'color': instance.color,
      'price': instance.price,
      'quantity': instance.quantity,
      'imageUrl': instance.imageUrl,
    };

_ShippingAddress _$ShippingAddressFromJson(Map<String, dynamic> json) =>
    _ShippingAddress(
      fullName: json['fullName'] as String,
      phone: json['phone'] as String,
      addressLine: json['addressLine'] as String,
      city: json['city'] as String,
    );

Map<String, dynamic> _$ShippingAddressToJson(_ShippingAddress instance) =>
    <String, dynamic>{
      'fullName': instance.fullName,
      'phone': instance.phone,
      'addressLine': instance.addressLine,
      'city': instance.city,
    };
