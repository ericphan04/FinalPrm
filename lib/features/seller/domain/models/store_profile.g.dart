// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'store_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StoreProfile _$StoreProfileFromJson(Map<String, dynamic> json) =>
    _StoreProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      description: json['description'] as String,
      address: json['address'] as String,
      logoUrl: json['logoUrl'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$StoreProfileToJson(_StoreProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'phone': instance.phone,
      'description': instance.description,
      'address': instance.address,
      'logoUrl': instance.logoUrl,
      'createdAt': instance.createdAt.toIso8601String(),
    };
