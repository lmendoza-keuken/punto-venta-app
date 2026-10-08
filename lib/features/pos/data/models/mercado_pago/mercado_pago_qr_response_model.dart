import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:punto_venta_app/features/pos/data/models/mercado_pago/config_qr_request_model.dart';
import 'package:punto_venta_app/features/pos/data/models/mercado_pago/transactions_qr_response_model.dart';

part 'mercado_pago_qr_response_model.freezed.dart';
part 'mercado_pago_qr_response_model.g.dart';

@freezed
class MercadoPagoQrResponse with _$MercadoPagoQrResponse {
  const factory MercadoPagoQrResponse({
    @JsonKey(name: 'id') String? id,
    @JsonKey(name: 'type') String? type,
    @JsonKey(name: 'processing_mode') String? processingMode,
    @JsonKey(name: 'external_reference') String? externalReference,
    @JsonKey(name: 'description') String? description,
    @JsonKey(name: 'total_amount') String? totalAmount,
    @JsonKey(name: 'total_paid_amount') String? totalPaidAmount,
    @JsonKey(name: 'expiration_time') String? expirationTime,
    @JsonKey(name: 'country_code') String? countryCode,
    @JsonKey(name: 'user_id') String? userId,
    @JsonKey(name: 'status') String? status,
    @JsonKey(name: 'status_detail') String? statusDetail,
    @JsonKey(name: 'currency') String? currency,
    @JsonKey(name: 'created_date') String? createdDate,
    @JsonKey(name: 'last_updated_date') String? lastUpdatedDate,
    @JsonKey(name: 'marketplace_fee') String? marketplaceFee,
    @JsonKey(name: 'config') ConfigQrRequest? config,
    @JsonKey(name: 'transactions') TransactionsQrResponse? transactions,
    @JsonKey(name: 'type_response') QrDataResponse? typeResponse,
  }) = _MercadoPagoQrResponse;

  factory MercadoPagoQrResponse.fromJson(Map<String, dynamic> json) =>
      _$MercadoPagoQrResponseFromJson(json);
}

@freezed
class QrDataResponse with _$QrDataResponse {
  const factory QrDataResponse({
    @JsonKey(name: 'qr_data') String? qrData,
  }) = _QrDataResponse;

  factory QrDataResponse.fromJson(Map<String, dynamic> json) =>
      _$QrDataResponseFromJson(json);
}
