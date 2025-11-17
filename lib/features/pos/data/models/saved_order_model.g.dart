// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_order_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SavedOrderModel _$SavedOrderModelFromJson(Map<String, dynamic> json) =>
    SavedOrderModel(
      id: json['id'] as String,
      name: json['name'] as String,
      items: (json['items'] as List<dynamic>)
          .map((e) => CartItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      clientName: json['client_name'] as String?,
      log: (json['log'] as List<dynamic>?)
              ?.map(
                  (e) => CartLogEntryModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$SavedOrderModelToJson(SavedOrderModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'items': instance.items,
      'total': instance.total,
      'created_at': instance.createdAt.toIso8601String(),
      'client_name': instance.clientName,
      'log': instance.log,
    };
