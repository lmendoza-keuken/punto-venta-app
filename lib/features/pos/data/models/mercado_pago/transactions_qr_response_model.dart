import 'package:freezed_annotation/freezed_annotation.dart';

part 'transactions_qr_response_model.freezed.dart';
part 'transactions_qr_response_model.g.dart';

@freezed
class TransactionsQrResponse with _$TransactionsQrResponse {
  const factory TransactionsQrResponse({
    @JsonKey(name: 'payments') List<PaymentsQrResponse>? payments,
    @JsonKey(name: 'refunds') List<RefundsQrResponse>? refunds,
  }) = _TransactionsQrResponse;

  factory TransactionsQrResponse.fromJson(Map<String, dynamic> json) =>
      _$TransactionsQrResponseFromJson(json);
}

@freezed
class PaymentsQrResponse with _$PaymentsQrResponse {
  const factory PaymentsQrResponse({
    @JsonKey(name: 'id') String? id,
    @JsonKey(name: 'amount') String? amount,
    @JsonKey(name: 'refunded_amount') String? refundedAmount,
    @JsonKey(name: 'paid_amount') String? paidAmount,
    @JsonKey(name: 'status') String? status,
    @JsonKey(name: 'status_detail') String? statusDetail,
    @JsonKey(name: 'reference_id') String? referenceId,
    @JsonKey(name: 'payment_method') PaymentMethodMp? paymentMethod,
    @JsonKey(name: 'discounts') DiscountsPaymentMp? discounts,
  }) = _PaymentsQrResponse;

  factory PaymentsQrResponse.fromJson(Map<String, dynamic> json) =>
      _$PaymentsQrResponseFromJson(json);
}

@freezed
class PaymentMethodMp with _$PaymentMethodMp {
  const factory PaymentMethodMp({
    @JsonKey(name: 'id') String? id,
    @JsonKey(name: 'type') String? type,
    @JsonKey(name: 'installments') int? installments,
  }) = _PaymentMethodMp;

  factory PaymentMethodMp.fromJson(Map<String, dynamic> json) =>
      _$PaymentMethodMpFromJson(json);
}

@freezed
class DiscountsPaymentMp with _$DiscountsPaymentMp {
  const factory DiscountsPaymentMp({
    @JsonKey(name: 'type') String? type,
  }) = _DiscountsPaymentMp;

  factory DiscountsPaymentMp.fromJson(Map<String, dynamic> json) =>
      _$DiscountsPaymentMpFromJson(json);
}

@freezed
class RefundsQrResponse with _$RefundsQrResponse {
  const factory RefundsQrResponse({
    @JsonKey(name: 'id') String? id,
    @JsonKey(name: 'transaction_id') String? transactionId,
    @JsonKey(name: 'reference_id') String? referenceId,
    @JsonKey(name: 'amount') String? amount,
    @JsonKey(name: 'status') String? status,
  }) = _RefundsQrResponse;

  factory RefundsQrResponse.fromJson(Map<String, dynamic> json) =>
      _$RefundsQrResponseFromJson(json);
}
