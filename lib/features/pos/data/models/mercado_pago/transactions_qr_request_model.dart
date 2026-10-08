import 'package:freezed_annotation/freezed_annotation.dart';

part 'transactions_qr_request_model.freezed.dart';
part 'transactions_qr_request_model.g.dart';

@freezed
class TransactionsQrRequest with _$TransactionsQrRequest {
  const factory TransactionsQrRequest({
    @JsonKey(name: 'payments', toJson: _paymentsToJson)
    List<PaymentsQrRequest>? payments,
  }) = _TransactionsQrRequest;

  factory TransactionsQrRequest.fromJson(Map<String, dynamic> json) =>
      _$TransactionsQrRequestFromJson(json);
}

List<Map<String, dynamic>>? _paymentsToJson(
        List<PaymentsQrRequest>? payments) =>
    payments?.map((e) => e.toJson()).toList();

@freezed
class PaymentsQrRequest with _$PaymentsQrRequest {
  const factory PaymentsQrRequest({
    @JsonKey(name: 'amount') String? amount,
  }) = _PaymentsQrRequest;

  factory PaymentsQrRequest.fromJson(Map<String, dynamic> json) =>
      _$PaymentsQrRequestFromJson(json);
}
