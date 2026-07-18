import 'package:freezed_annotation/freezed_annotation.dart';

part 'cart_item.freezed.dart';
part 'cart_item.g.dart';

@freezed
abstract class CartItem with _$CartItem {
  const factory CartItem({
    required String id,
    required String productId,
    required String variantId,
    required String productName,
    required String imageUrl,
    required String size,
    required String color,
    required double price,
    @Default(1) int quantity,
    required DateTime addedAt,
  }) = _CartItem;

  factory CartItem.fromJson(Map<String, dynamic> json) => _$CartItemFromJson(json);
}
