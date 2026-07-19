// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AuditLog _$AuditLogFromJson(Map<String, dynamic> json) => _AuditLog(
  id: json['id'] as String,
  actorUid: json['actorUid'] as String,
  actorRole: json['actorRole'] as String,
  action: json['action'] as String,
  targetType: json['targetType'] as String,
  targetId: json['targetId'] as String,
  reason: json['reason'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$AuditLogToJson(_AuditLog instance) => <String, dynamic>{
  'id': instance.id,
  'actorUid': instance.actorUid,
  'actorRole': instance.actorRole,
  'action': instance.action,
  'targetType': instance.targetType,
  'targetId': instance.targetId,
  'reason': instance.reason,
  'createdAt': instance.createdAt.toIso8601String(),
};
