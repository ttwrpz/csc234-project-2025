// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token_balance.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TokenBalance _$TokenBalanceFromJson(Map<String, dynamic> json) =>
    _TokenBalance(
      balance: (json['balance'] as num).toInt(),
      earnedToday: (json['earnedToday'] as num).toInt(),
      lastEarnedDate: json['lastEarnedDate'] == null
          ? null
          : DateTime.parse(json['lastEarnedDate'] as String),
    );

Map<String, dynamic> _$TokenBalanceToJson(_TokenBalance instance) =>
    <String, dynamic>{
      'balance': instance.balance,
      'earnedToday': instance.earnedToday,
      'lastEarnedDate': instance.lastEarnedDate?.toIso8601String(),
    };
