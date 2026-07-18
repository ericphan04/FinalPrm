// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Product _$ProductFromJson(Map<String, dynamic> json) => _Product(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  categoryId: json['categoryId'] as String,
  basePrice: (json['basePrice'] as num).toDouble(),
  images:
      (json['images'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  isAvailable: json['isAvailable'] as bool? ?? true,
  createdAt: DateTime.parse(json['createdAt'] as String),
  variants:
      (json['variants'] as List<dynamic>?)
          ?.map((e) => ProductVariant.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$ProductToJson(_Product instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'categoryId': instance.categoryId,
  'basePrice': instance.basePrice,
  'images': instance.images,
  'isAvailable': instance.isAvailable,
  'createdAt': instance.createdAt.toIso8601String(),
  'variants': instance.variants,
};

_ProductVariant _$ProductVariantFromJson(Map<String, dynamic> json) =>
    _ProductVariant(
      id: json['id'] as String,
      size: json['size'] as String,
      color: json['color'] as String,
      stockQuantity: (json['stockQuantity'] as num?)?.toInt() ?? 0,
      priceDifference: (json['priceDifference'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$ProductVariantToJson(_ProductVariant instance) =>
    <String, dynamic>{
      'id': instance.id,
      'size': instance.size,
      'color': instance.color,
      'stockQuantity': instance.stockQuantity,
      'priceDifference': instance.priceDifference,
    };
