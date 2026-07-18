import 'package:freezed_annotation/freezed_annotation.dart';

part 'seller_application.freezed.dart';
part 'seller_application.g.dart';

enum SellerApplicationStatus {
  pending,
  approved,
  rejected;

  String get nameVi {
    switch (this) {
      case SellerApplicationStatus.pending:
        return 'Chờ duyệt';
      case SellerApplicationStatus.approved:
        return 'Đã duyệt';
      case SellerApplicationStatus.rejected:
        return 'Bị từ chối';
    }
  }
}

@freezed
abstract class SellerApplication with _$SellerApplication {
  const factory SellerApplication({
    required String id,
    required String storeName,
    required String phone,
    required String description,
    required String address,
    @Default(SellerApplicationStatus.pending) SellerApplicationStatus status,
    String? rejectReason,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _SellerApplication;

  factory SellerApplication.fromJson(Map<String, dynamic> json) =>
      _$SellerApplicationFromJson(json);
}
