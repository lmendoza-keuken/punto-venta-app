import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:punto_venta_app/features/pos/data/models/tax_model.dart';
import 'package:punto_venta_app/features/pos/data/models/ticket_models/item_ticket_model.dart';

part 'ticket_request_model.freezed.dart';
part 'ticket_request_model.g.dart';

@freezed
class TicketRequestModel with _$TicketRequestModel {
  const TicketRequestModel._();

  const factory TicketRequestModel({
    @JsonKey(name: 'ticketId') String? ticketId,
    @JsonKey(name: 'timestamp') String? timestamp,
    @JsonKey(name: 'cashier') int? cashier,
    @JsonKey(name: 'client') String? client, // TODO: modelo de client
    @JsonKey(name: 'paymentMethod') int? paymentMethod,
    @JsonKey(name: 'total') double? total,
    @JsonKey(name: 'branch_number') int? branchNumber,
    @JsonKey(name: 'branch_id') int? branchId,
    @JsonKey(name: 'totalTax', toJson: _taxesToJson) List<TaxModel>? totalTax,
    @JsonKey(name: 'items', toJson: _itemsToJson) List<ItemTicketModel>? items,
  }) = _TicketRequestModel;

  factory TicketRequestModel.fromJson(Map<String, dynamic> json) =>
      _$TicketRequestModelFromJson(json);
}

List<Map<String, dynamic>>? _taxesToJson(List<TaxModel>? taxes) =>
    taxes?.map((e) => e.toJson()).toList();

List<Map<String, dynamic>>? _itemsToJson(List<ItemTicketModel>? items) =>
    items?.map((e) => e.toJson()).toList();
