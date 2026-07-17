// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppUser _$AppUserFromJson(Map<String, dynamic> json) => _AppUser(
  uid: json['uid'] as String,
  email: json['email'] as String,
  displayName: json['displayName'] as String,
  photoUrl: json['photoUrl'] as String,
  role: $enumDecode(_$AppUserRoleEnumMap, json['role']),
);

Map<String, dynamic> _$AppUserToJson(_AppUser instance) => <String, dynamic>{
  'uid': instance.uid,
  'email': instance.email,
  'displayName': instance.displayName,
  'photoUrl': instance.photoUrl,
  'role': _$AppUserRoleEnumMap[instance.role]!,
};

const _$AppUserRoleEnumMap = {
  AppUserRole.guest: 'guest',
  AppUserRole.user: 'user',
  AppUserRole.seller: 'seller',
  AppUserRole.admin: 'admin',
};
