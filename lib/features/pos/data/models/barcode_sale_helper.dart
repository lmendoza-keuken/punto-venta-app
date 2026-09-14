import 'package:punto_venta_app/features/pos/data/models/barcode_model.dart';

/// Tipo de venta asociado a un código de barras (Unidad / Pack / Bulto).
class BarcodeSaleInfo {
  /// 1 Unidad, 2 Pack, 3 Bulto
  final int type;

  /// Multiplicador de cantidad (ej. 15 para un bulto).
  final int units;

  const BarcodeSaleInfo({
    required this.type,
    required this.units,
  });

  /// Cantidad a enviar al carrito: [selectedQty] × [units].
  int quantityFor(int selectedQty) => selectedQty * units;

  /// Texto para snackbar / UI.
  String get label {
    switch (type) {
      case 1:
        return 'Unidad';
      case 2:
        return 'Pack ($units unidades)';
      case 3:
        return 'Bulto ($units unidades)';
      default:
        return '';
    }
  }
}

/// Resuelve Unidad/Pack/Bulto desde [type]/[units] (p.ej. barcode_type / barcode_units).
BarcodeSaleInfo? resolveBarcodeSaleInfo({int? type, int? units}) {
  if (type == null) return null;
  return BarcodeSaleInfo(type: type, units: units ?? 1);
}

/// Resuelve desde un [BarcodeModel] (match local o sintetizado del API individual).
BarcodeSaleInfo? resolveBarcodeSaleInfoFromBarcode(BarcodeModel? barcode) {
  if (barcode == null) return null;
  return resolveBarcodeSaleInfo(type: barcode.type, units: barcode.units);
}
