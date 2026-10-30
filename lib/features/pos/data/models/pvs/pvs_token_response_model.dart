import 'package:freezed_annotation/freezed_annotation.dart';

part 'pvs_token_response_model.freezed.dart';
part 'pvs_token_response_model.g.dart';

@freezed
class PvsTokenResponse with _$PvsTokenResponse {
  const factory PvsTokenResponse({
    @JsonKey(name: 'access_token') String? accessToken,
    @JsonKey(name: 'expires_in') int? expiresIn,
    @JsonKey(name: 'refresh_expires_in') int? refreshExpiresIn,
    @JsonKey(name: 'token_type') String? tokenType,
    @JsonKey(name: 'not-before-policy') int? notBeforePolicy,
    @JsonKey(name: 'scope') String? scope,
  }) = _PvsTokenResponse;

  factory PvsTokenResponse.fromJson(Map<String, dynamic> json) =>
      _$PvsTokenResponseFromJson(json);
}
