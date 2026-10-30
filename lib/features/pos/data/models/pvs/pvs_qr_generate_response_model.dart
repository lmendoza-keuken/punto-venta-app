import 'package:freezed_annotation/freezed_annotation.dart';

part 'pvs_qr_generate_response_model.freezed.dart';
part 'pvs_qr_generate_response_model.g.dart';

@freezed
class PvsQrGenerateResponse with _$PvsQrGenerateResponse {
  const factory PvsQrGenerateResponse({
    @JsonKey(name: 'code') String? code,
    @JsonKey(name: 'message') String? message,
    @JsonKey(name: 'ok') bool? ok,
    @JsonKey(name: 'data') PvsQrGenerateData? data,
  }) = _PvsQrGenerateResponse;

  factory PvsQrGenerateResponse.fromJson(Map<String, dynamic> json) =>
      _$PvsQrGenerateResponseFromJson(json);
}

@freezed
class PvsQrGenerateData with _$PvsQrGenerateData {
  const factory PvsQrGenerateData({
    @JsonKey(name: 'qrId') String? qrId,
    @JsonKey(name: 'qrImage') String? qrImage,
    @JsonKey(name: 'qrRaw') String? qrRaw,
    @JsonKey(name: 'date') String? date,
    @JsonKey(name: 'expiration') int? expiration,
  }) = _PvsQrGenerateData;

  factory PvsQrGenerateData.fromJson(Map<String, dynamic> json) =>
      _$PvsQrGenerateDataFromJson(json);
}
