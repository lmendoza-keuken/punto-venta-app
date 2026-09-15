import 'package:freezed_annotation/freezed_annotation.dart';

part 'pending_canceled_items_response_model.freezed.dart';
part 'pending_canceled_items_response_model.g.dart';

@freezed
class PendingCanceledTicketModel with _$PendingCanceledTicketModel {
  const PendingCanceledTicketModel._();

  const factory PendingCanceledTicketModel({
    @JsonKey(name: 'ticketId') String? ticketId,
    @JsonKey(name: 'description') String? description,
    @JsonKey(name: 'timestamp') String? timestamp,
    @JsonKey(name: 'canceled_items') List<CanceledItemModel>? canceledItems,
  }) = _PendingCanceledTicketModel;

  factory PendingCanceledTicketModel.fromJson(Map<String, dynamic> json) =>
      _$PendingCanceledTicketModelFromJson(json);

  int get canceledItemsCount =>
      canceledItems?.fold<int>(
            0,
            (sum, item) => sum + (item.quantity ?? 0).round(),
          ) ??
          0;
}

@freezed
class CanceledItemModel with _$CanceledItemModel {
  const factory CanceledItemModel({
    @JsonKey(name: 'productId') int? productId,
    @JsonKey(name: 'productName') String? productName,
    @JsonKey(name: 'quantity') double? quantity,
    @JsonKey(name: 'is_weighted') String? isWeighted,
    @JsonKey(name: 'weight') double? weight,
  }) = _CanceledItemModel;

  factory CanceledItemModel.fromJson(Map<String, dynamic> json) =>
      _$CanceledItemModelFromJson(json);
}
