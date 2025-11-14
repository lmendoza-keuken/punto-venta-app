// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'completed_order_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CompletedOrderModel _$CompletedOrderModelFromJson(Map<String, dynamic> json) =>
    CompletedOrderModel(
      id: json['id'] as String,
      orderNumber: json['order_number'] as String,
      items: (json['items'] as List<dynamic>)
          .map((e) => CartItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toDouble(),
      completedAt: DateTime.parse(json['completed_at'] as String),
      clientName: json['client_name'] as String?,
      cashierName: json['cashier_name'] as String,
      paymentMethod: json['payment_method'] as String,
      totalTax: (json['total_tax'] as num).toDouble(),
      totalItems: (json['total_items'] as num).toInt(),
    );

Map<String, dynamic> _$CompletedOrderModelToJson(
        CompletedOrderModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'order_number': instance.orderNumber,
      'items': instance.items,
      'total': instance.total,
      'completed_at': instance.completedAt.toIso8601String(),
      'client_name': instance.clientName,
      'cashier_name': instance.cashierName,
      'payment_method': instance.paymentMethod,
      'total_tax': instance.totalTax,
      'total_items': instance.totalItems,
    };
