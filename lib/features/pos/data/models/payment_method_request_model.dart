import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment_method_request_model.freezed.dart';
part 'payment_method_request_model.g.dart';

@freezed
class PaymentMethodRequestModel with _$PaymentMethodRequestModel {
  const PaymentMethodRequestModel._();

  const factory PaymentMethodRequestModel({
    @JsonKey(name: 'id') int? id,
    @JsonKey(name: 'amount') double? amount,
    @JsonKey(name: 'details') PaymentMethodDetailRequest? details,
  }) = _PaymentMethodRequestModel;

  factory PaymentMethodRequestModel.fromJson(Map<String, dynamic> json) =>
      _$PaymentMethodRequestModelFromJson(json);
}

@freezed
class PaymentMethodDetailRequest with _$PaymentMethodDetailRequest {
  const PaymentMethodDetailRequest._();

  const factory PaymentMethodDetailRequest({
    @JsonKey(name: 'account_owner') String? accountOwner,
    @JsonKey(name: 'bank_id') String? bankId,
    @JsonKey(name: 'check_number') String? checkNumber,
    @JsonKey(name: 'transfer_id') String? transferId,
    @JsonKey(name: 'verification_id') String? verificationId,
  }) = _PaymentMethodDetailRequest;

  factory PaymentMethodDetailRequest.fromJson(Map<String, dynamic> json) =>
      _$PaymentMethodDetailRequestFromJson(json);
}
