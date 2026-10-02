import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:punto_venta_app/core/utils/enums.dart';
import 'package:punto_venta_app/features/pos/domain/entities/payment_method.dart';

part 'payment_method_model.freezed.dart';
part 'payment_method_model.g.dart';

@freezed
class PaymentMethodModel with _$PaymentMethodModel {
  const PaymentMethodModel._();

  const factory PaymentMethodModel({
    @JsonKey(name: 'id') int? id,
    @JsonKey(name: 'description') String? description,
    @JsonKey(name: 'short_description') String? shortDescription,
    @JsonKey(name: 'deleted_at') String? deletedAt,
    @JsonKey(name: 'qr_type', fromJson: qrTypeFromJson, toJson: qrTypeToJson)
    QrType? qrType,
  }) = _PaymentMethodModel;

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) =>
      _$PaymentMethodModelFromJson(json);

  factory PaymentMethodModel.fromEntity(PaymentMethod pm) {
    return PaymentMethodModel(
      id: pm.id,
      description: pm.description,
      shortDescription: pm.shortDescription,
      deletedAt: pm.deleteAt,
      qrType: pm.qrType,
    );
  }

  PaymentMethod toEntity() {
    return PaymentMethod(
      id: id ?? 0,
      description: description ?? "",
      shortDescription: shortDescription ?? "",
      deleteAt: deletedAt ?? "",
      qrType: qrType ?? _inferQrType(description, shortDescription),
    );
  }
}

/// Mientras el backend no envíe `qr_type`, se infiere por descripción.
QrType? _inferQrType(String? description, String? shortDescription) {
  final text =
      '${description ?? ''} ${shortDescription ?? ''}'.toLowerCase();
  if (text.contains('pvs')) return QrType.pvs;
  if (text.contains('mercadopago') || text.contains('mercado pago')) {
    return QrType.mp;
  }
  return null;
}
