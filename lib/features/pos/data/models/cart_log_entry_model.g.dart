// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_log_entry_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CartLogEntryModel _$CartLogEntryModelFromJson(Map<String, dynamic> json) =>
    CartLogEntryModel(
      id: json['id'] as String,
      type: json['type'] as String,
      item: CartItemModel.fromJson(json['item'] as Map<String, dynamic>),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$CartLogEntryModelToJson(CartLogEntryModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'item': instance.item,
      'timestamp': instance.timestamp.toIso8601String(),
    };
