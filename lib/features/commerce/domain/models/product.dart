import 'package:freezed_annotation/freezed_annotation.dart';

part 'product.freezed.dart';
part 'product.g.dart';

enum ProductStatus {
  draft,
  pendingReview,
  published,
  rejected;

  String get nameVi {
    switch (this) {
      case ProductStatus.draft:
        return 'Nháp';
      case ProductStatus.pendingReview:
        return 'Chờ duyệt';
      case ProductStatus.published:
        return 'Đã duyệt/Đang bán';
      case ProductStatus.rejected:
        return 'Bị từ chối';
    }
  }
}

@freezed
abstract class Product with _$Product {
  const factory Product({
    required String id,
    required String name,
    required String description,
    required String categoryId,
    required double basePrice,
    required String sellerId,
    @Default(ProductStatus.draft) ProductStatus status,
    String? rejectReason,
    @Default([]) List<String> images,
    @Default(true) bool isAvailable,
    required DateTime createdAt,
    @Default([]) List<ProductVariant> variants,
  }) = _Product;

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);
}

@freezed
abstract class ProductVariant with _$ProductVariant {
  const factory ProductVariant({
    required String id,
    required String size,
    required String color,
    required String sku,
    @Default(0) int stockQuantity,
    @Default(0.0) double priceDifference,
  }) = _ProductVariant;

  factory ProductVariant.fromJson(Map<String, dynamic> json) =>
      _$ProductVariantFromJson(json);
}
