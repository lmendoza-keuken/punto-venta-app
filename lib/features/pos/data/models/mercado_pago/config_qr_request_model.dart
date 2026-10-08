import 'package:freezed_annotation/freezed_annotation.dart';

part 'config_qr_request_model.freezed.dart';
part 'config_qr_request_model.g.dart';

@freezed
class ConfigQrRequest with _$ConfigQrRequest {
  const factory ConfigQrRequest({
    @JsonKey(name: 'qr') QrConfig? qr,
  }) = _ConfigQrRequest;

  factory ConfigQrRequest.fromJson(Map<String, dynamic> json) =>
      _$ConfigQrRequestFromJson(json);
}

@freezed
class QrConfig with _$QrConfig {
  const factory QrConfig({
    @JsonKey(name: 'external_pos_id') String? externalPosId,
    @JsonKey(name: 'mode') String? mode,
  }) = _QrConfig;

  factory QrConfig.fromJson(Map<String, dynamic> json) =>
      _$QrConfigFromJson(json);
}
