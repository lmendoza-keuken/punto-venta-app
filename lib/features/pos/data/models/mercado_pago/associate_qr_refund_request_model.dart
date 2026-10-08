import 'package:freezed_annotation/freezed_annotation.dart';

part 'associate_qr_refund_request_model.freezed.dart';
part 'associate_qr_refund_request_model.g.dart';

@freezed
class AssociateQrRefundRequest with _$AssociateQrRefundRequest {
  const factory AssociateQrRefundRequest({
    @JsonKey(name: 'nc_sale_id') required int ncSaleId,
    @JsonKey(name: 'refund_id') String? refundId,
    @JsonKey(name: 'in_cash') @Default(false) bool inCash,
  }) = _AssociateQrRefundRequest;

  factory AssociateQrRefundRequest.fromJson(Map<String, dynamic> json) =>
      _$AssociateQrRefundRequestFromJson(json);
}
