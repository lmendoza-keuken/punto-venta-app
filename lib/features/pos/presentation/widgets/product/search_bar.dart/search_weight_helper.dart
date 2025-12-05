import 'package:punto_venta_app/features/pos/domain/entities/product.dart';

class WeightBarcodeResult {
  final Product product;
  final double weightKg;
  final double calculatedUnitPrice;

  WeightBarcodeResult({
    required this.product,
    required this.weightKg,
    required this.calculatedUnitPrice,
  });
}

WeightBarcodeResult? parseWeightBarcode(String code, List<Product> products) {
  if (!(code.length == 13 &&
      (code.startsWith('20') || code.startsWith('21')))) {
    return null;
  }

  final weightString = code.substring(7, 12);
  final codeString = code.substring(2, 7);
  final weightInt = int.tryParse(weightString) ?? 0;
  final singleWeight = weightInt / 1000.0;
  final weightKg = singleWeight;

  final found = products.cast<Product?>().firstWhere(
    (p) {
      final pcode = p?.code ?? '';
      if (pcode == codeString) return true;
      try {
        final idFromCode = int.parse(codeString);
        if (p?.id == idFromCode) return true;
      } catch (_) {}
      if (pcode.endsWith(codeString)) return true;
      return false;
    },
    orElse: () => null,
  );

  if (found == null) return null;

  final netWeight = found.netWeight;
  final priceNetWeight = netWeight > 0 ? found.precio ?? 0.0 : 0.0;
  final calculatedUnitPrice =
      priceNetWeight * weightKg / (netWeight > 0 ? netWeight : 1);

  return WeightBarcodeResult(
    product: found,
    weightKg: weightKg,
    calculatedUnitPrice: calculatedUnitPrice,
  );
}
