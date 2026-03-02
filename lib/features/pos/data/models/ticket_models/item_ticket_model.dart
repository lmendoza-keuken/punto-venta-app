import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:punto_venta_app/features/pos/data/models/tax_model.dart';

part 'item_ticket_model.freezed.dart';
part 'item_ticket_model.g.dart';

@freezed
class ItemTicketModel with _$ItemTicketModel {
  const ItemTicketModel._();

  const factory ItemTicketModel({
    @JsonKey(name: 'id') String? id,
    @JsonKey(name: 'type') String? type,
    @JsonKey(name: 'productId') int? productId,
    @JsonKey(name: 'productName') String? productName, 
    @JsonKey(name: 'quantity') int? quantity,
    @JsonKey(name: 'discount') double? discount,
    @JsonKey(name: 'unitPrice') double? unitPrice,
    @JsonKey(name: 'priceListId') int? priceListId,
    @JsonKey(name: 'taxes', toJson: _taxesToJson) List<TaxModel>? taxes,
    @JsonKey(name: 'is_weighted') String? isWeighted,
    @JsonKey(name: 'net_weight') double? netWeight,
    @JsonKey(name: 'weight') double? weight,
  }) = _ItemTicketModel;

  factory ItemTicketModel.fromJson(Map<String, dynamic> json) =>
      _$ItemTicketModelFromJson(json);
}


List<Map<String, dynamic>>? _taxesToJson(
        List<TaxModel>? taxes) =>
    taxes?.map((e) => e.toJson()).toList();

