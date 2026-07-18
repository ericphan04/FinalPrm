// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seller_application.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SellerApplication _$SellerApplicationFromJson(Map<String, dynamic> json) =>
    _SellerApplication(
      id: json['id'] as String,
      storeName: json['storeName'] as String,
      phone: json['phone'] as String,
      description: json['description'] as String,
      address: json['address'] as String,
      status:
          $enumDecodeNullable(
            _$SellerApplicationStatusEnumMap,
            json['status'],
          ) ??
          SellerApplicationStatus.pending,
      rejectReason: json['rejectReason'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$SellerApplicationToJson(_SellerApplication instance) =>
    <String, dynamic>{
      'id': instance.id,
      'storeName': instance.storeName,
      'phone': instance.phone,
      'description': instance.description,
      'address': instance.address,
      'status': _$SellerApplicationStatusEnumMap[instance.status]!,
      'rejectReason': instance.rejectReason,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

const _$SellerApplicationStatusEnumMap = {
  SellerApplicationStatus.pending: 'pending',
  SellerApplicationStatus.approved: 'approved',
  SellerApplicationStatus.rejected: 'rejected',
};
