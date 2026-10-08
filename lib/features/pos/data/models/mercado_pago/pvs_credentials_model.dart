import 'package:freezed_annotation/freezed_annotation.dart';

part 'pvs_credentials_model.freezed.dart';
part 'pvs_credentials_model.g.dart';

@freezed
class PvsCredentials with _$PvsCredentials {
  factory PvsCredentials({
    @JsonKey(name: 'paymentMethodId') int? paymentMethodId,
    @JsonKey(name: 'clientId') String? clientId,
    @JsonKey(name: 'clientSecret') String? clientSecret,
  }) = _PvsCredentials;

  factory PvsCredentials.fromJson(Map<String, dynamic> json) =>
      _$PvsCredentialsFromJson(json);
}
