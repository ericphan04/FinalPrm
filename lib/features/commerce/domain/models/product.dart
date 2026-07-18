import 'package:freezed_annotation/freezed_annotation.dart';

part 'product.freezed.dart';
part 'product.g.dart';

@freezed
abstract class Product with _$Product {
  const factory Product({
    required String id,
    required String name,
    required String description,
    required String categoryId,
    required double basePrice,
    @Default([]) List<String> images,
    @Default(true) bool isAvailable,
    required DateTime createdAt,
    @Default([]) List<ProductVariant> variants,
  }) = _Product;

  factory Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);
}

@freezed
abstract class ProductVariant with _$ProductVariant {
  const factory ProductVariant({
    required String id,
    required String size,
    required String color,
    @Default(0) int stockQuantity,
    @Default(0.0) double priceDifference,
  }) = _ProductVariant;

  factory ProductVariant.fromJson(Map<String, dynamic> json) => _$ProductVariantFromJson(json);
}
