import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:punto_venta_app/features/pos/data/models/mercado_pago/transactions_qr_response_model.dart';

part 'order_refund_response_model.freezed.dart';
part 'order_refund_response_model.g.dart';

@freezed
class OrderRefundResponse with _$OrderRefundResponse {
  const factory OrderRefundResponse({
    @JsonKey(name: 'id') String? id,
    @JsonKey(name: 'status') String? status,
    @JsonKey(name: 'status_detail') String? statusDetail,
    @JsonKey(name: 'transactions') OrderRefundTransactions? transactions,
  }) = _OrderRefundResponse;

  factory OrderRefundResponse.fromJson(Map<String, dynamic> json) =>
      _$OrderRefundResponseFromJson(json);
}

@freezed
class OrderRefundTransactions with _$OrderRefundTransactions {
  const factory OrderRefundTransactions({
    @JsonKey(name: 'refunds') List<RefundsQrResponse>? refunds,
  }) = _OrderRefundTransactions;

  factory OrderRefundTransactions.fromJson(Map<String, dynamic> json) =>
      _$OrderRefundTransactionsFromJson(json);
}
