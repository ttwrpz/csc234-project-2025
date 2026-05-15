// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pin_hash.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PinHash _$PinHashFromJson(Map<String, dynamic> json) => _PinHash(
  algorithm: json['algorithm'] as String,
  iterations: (json['iterations'] as num).toInt(),
  saltBase64: json['saltBase64'] as String,
  hashBase64: json['hashBase64'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  failedAttempts: (json['failedAttempts'] as num?)?.toInt() ?? 0,
  lockedUntil: json['lockedUntil'] == null
      ? null
      : DateTime.parse(json['lockedUntil'] as String),
);

Map<String, dynamic> _$PinHashToJson(_PinHash instance) => <String, dynamic>{
  'algorithm': instance.algorithm,
  'iterations': instance.iterations,
  'saltBase64': instance.saltBase64,
  'hashBase64': instance.hashBase64,
  'createdAt': instance.createdAt.toIso8601String(),
  'failedAttempts': instance.failedAttempts,
  'lockedUntil': instance.lockedUntil?.toIso8601String(),
};
