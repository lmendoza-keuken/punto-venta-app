import 'package:freezed_annotation/freezed_annotation.dart';

part 'pvs_qr_generate_request_model.freezed.dart';
part 'pvs_qr_generate_request_model.g.dart';

/// Formatea el monto como exige PVS: string con exactamente 2 decimales.
String formatPvsAmount(double value) {
  final rounded = (value * 100).round() / 100;
  return rounded.toStringAsFixed(2);
}

@freezed
class PvsQrGenerateRequest with _$PvsQrGenerateRequest {
  const factory PvsQrGenerateRequest({
    @JsonKey(name: 'amount') required String amount,
    @JsonKey(name: 'externalId') required String externalId,
    @JsonKey(name: 'reference') required String reference,
  }) = _PvsQrGenerateRequest;

  factory PvsQrGenerateRequest.fromJson(Map<String, dynamic> json) =>
      _$PvsQrGenerateRequestFromJson(json);
}
