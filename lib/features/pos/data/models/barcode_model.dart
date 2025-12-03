import 'package:freezed_annotation/freezed_annotation.dart';

part 'barcode_model.freezed.dart';
part 'barcode_model.g.dart';

@freezed
class BarcodeModel with _$BarcodeModel {
  const BarcodeModel._();

  const factory BarcodeModel({
    required int codigo,
    @JsonKey(name: 'barcode') required int codigoBarra,
    required int unidades,
    required int tipoVenta,
  }) = _BarcodeModel;

  factory BarcodeModel.fromJson(Map<String, dynamic> json) =>
      _$BarcodeModelFromJson(json);

  bool get isWeighted => codigoBarra.toString().startsWith('20');

  String get tipoVentaTexto {
    switch (tipoVenta) {
      case 1:
        return 'Unidad';
      case 2:
        return 'Pack';
      case 3:
        return 'Bulto';
      default:
        return 'Desconocido';
    }
  }
}
