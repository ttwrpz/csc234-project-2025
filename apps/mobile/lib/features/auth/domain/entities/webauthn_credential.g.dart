// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'webauthn_credential.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WebauthnCredential _$WebauthnCredentialFromJson(Map<String, dynamic> json) =>
    _WebauthnCredential(
      credentialId: json['credentialId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUsedAt: json['lastUsedAt'] == null
          ? null
          : DateTime.parse(json['lastUsedAt'] as String),
      failedAttempts: (json['failedAttempts'] as num?)?.toInt() ?? 0,
      lockedUntil: json['lockedUntil'] == null
          ? null
          : DateTime.parse(json['lockedUntil'] as String),
    );

Map<String, dynamic> _$WebauthnCredentialToJson(_WebauthnCredential instance) =>
    <String, dynamic>{
      'credentialId': instance.credentialId,
      'createdAt': instance.createdAt.toIso8601String(),
      'lastUsedAt': instance.lastUsedAt?.toIso8601String(),
      'failedAttempts': instance.failedAttempts,
      'lockedUntil': instance.lockedUntil?.toIso8601String(),
    };
