// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CartItem _$CartItemFromJson(Map<String, dynamic> json) => _CartItem(
  id: json['id'] as String,
  productId: json['productId'] as String,
  variantId: json['variantId'] as String,
  productName: json['productName'] as String,
  imageUrl: json['imageUrl'] as String,
  size: json['size'] as String,
  color: json['color'] as String,
  price: (json['price'] as num).toDouble(),
  quantity: (json['quantity'] as num?)?.toInt() ?? 1,
  addedAt: DateTime.parse(json['addedAt'] as String),
);

Map<String, dynamic> _$CartItemToJson(_CartItem instance) => <String, dynamic>{
  'id': instance.id,
  'productId': instance.productId,
  'variantId': instance.variantId,
  'productName': instance.productName,
  'imageUrl': instance.imageUrl,
  'size': instance.size,
  'color': instance.color,
  'price': instance.price,
  'quantity': instance.quantity,
  'addedAt': instance.addedAt.toIso8601String(),
};
