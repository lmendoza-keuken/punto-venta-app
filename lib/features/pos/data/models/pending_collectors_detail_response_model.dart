import 'package:freezed_annotation/freezed_annotation.dart';

part 'pending_collectors_detail_response_model.freezed.dart';
part 'pending_collectors_detail_response_model.g.dart';

@freezed
class PendingCollectorsDetailResponseModel
    with _$PendingCollectorsDetailResponseModel {
  const PendingCollectorsDetailResponseModel._();

  const factory PendingCollectorsDetailResponseModel({
    @JsonKey(name: 'invoice_count') int? invoiceCount,
    @JsonKey(name: 'nc_count') int? creditNoteCount,
    @JsonKey(name: 'canceled_items_count') int? canceledItemsCount,
    @JsonKey(name: 'payments_breakdown')
    List<PaymentBreakdown>? paymentsBreakdown,
    @JsonKey(name: 'invoice_total') double? invoiceTotal,
    @JsonKey(name: 'nc_total') double? creditNoteTotal,
  }) = _PendingCollectorsDetailResponseModel;

  factory PendingCollectorsDetailResponseModel.fromJson(
    Map<String, dynamic> json,
  ) =>
      _$PendingCollectorsDetailResponseModelFromJson(json);
}

@freezed
class PaymentBreakdown with _$PaymentBreakdown {
  const factory PaymentBreakdown({
    @JsonKey(name: 'payment_method_id') int? paymentMethodId,
    @JsonKey(name: 'description') String? description,
    @JsonKey(name: 'total_amount') double? totalAmount,
  }) = _PaymentBreakdown;

  factory PaymentBreakdown.fromJson(Map<String, dynamic> json) =>
      _$PaymentBreakdownFromJson(json);
}
