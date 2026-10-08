import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:punto_venta_app/features/pos/data/models/mercado_pago/config_qr_request_model.dart';
import 'package:punto_venta_app/features/pos/data/models/mercado_pago/transactions_qr_request_model.dart';

part 'mercado_pago_qr_request_model.freezed.dart';
part 'mercado_pago_qr_request_model.g.dart';

@freezed
class MercadoPagoQrRequest with _$MercadoPagoQrRequest {
  const factory MercadoPagoQrRequest({
    @JsonKey(name: 'type') String? type,
    @JsonKey(name: 'total_amount') String? totalAmount,
    @JsonKey(name: 'description') String? description,
    @JsonKey(name: 'external_reference') String? externalReference,
    @JsonKey(name: 'expiration_time') String? expirationTime,
    @JsonKey(name: 'config', toJson: _configToJson) ConfigQrRequest? config,
    @JsonKey(name: 'transactions', toJson: _transactionsToJson)
    TransactionsQrRequest? transactions,
  }) = _MercadoPagoQrRequest;

  factory MercadoPagoQrRequest.fromJson(Map<String, dynamic> json) =>
      _$MercadoPagoQrRequestFromJson(json);
}

Map<String, dynamic>? _configToJson(ConfigQrRequest? config) =>
    config?.toJson();

Map<String, dynamic>? _transactionsToJson(
        TransactionsQrRequest? transactions) =>
    transactions?.toJson();
