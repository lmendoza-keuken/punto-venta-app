import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:punto_venta_app/features/pos/data/models/tax_model.dart';
import 'package:punto_venta_app/features/pos/data/models/ticket_models/item_ticket_model.dart';

part 'ticket_response_model.freezed.dart';
part 'ticket_response_model.g.dart';

@freezed
class TicketResponseModel with _$TicketResponseModel {
  const TicketResponseModel._();

  const factory TicketResponseModel({
    @JsonKey(name: 'ticketId') String? ticketId,
    @JsonKey(name: 'timestamp') String? timestamp,
    @JsonKey(name: 'cashier') int? cashier,
    @JsonKey(name: 'client') String? client, // TODO: modelo de client
    @JsonKey(name: 'paymentMethod') int? paymentMethod,
    @JsonKey(name: 'total') double? total,
    @JsonKey(name: 'branch_number') int? branchNumber,
    @JsonKey(name: 'branch_id') int? branchId,
    @JsonKey(name: 'totalTax') List<TaxModel>? totalTax,
    @JsonKey(name: 'items') List<ItemTicketModel>? items, 
    @JsonKey(name: 'external_id') int? externalId,
    @JsonKey(name: 'type_code') String? typeCode,
    
  }) = _TicketResponseModel;

  factory TicketResponseModel.fromJson(Map<String, dynamic> json) =>
      _$TicketResponseModelFromJson(json);
}

