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

  bool get hasEmbeddedWeight => weightKg > 0;
}

/// EAN-13 de balanza parseado: PLU + peso, sin resolver el producto.
class ParsedWeightBarcode {
  /// substring(2, 7) — PLU / código de producto
  final String productKey;

  /// Gramos en [7..12) / 1000
  final double weightKg;

  const ParsedWeightBarcode({
    required this.productKey,
    required this.weightKg,
  });
}

/// EAN-13 de balanza: prefijo 20/21, PLU en [2..7), peso en gramos en [7..12).
ParsedWeightBarcode? tryParseWeightBarcode(String code) {
  if (!(code.length == 13 &&
      (code.startsWith('20') || code.startsWith('21')))) {
    return null;
  }

  final weightString = code.substring(7, 12);
  final productKey = code.substring(2, 7);
  final weightInt = int.tryParse(weightString) ?? 0;
  final weightKg = weightInt / 1000.0;

  return ParsedWeightBarcode(
    productKey: productKey,
    weightKg: weightKg,
  );
}

Product? matchWeightedProductLocal(List<Product> products, String productKey) {
  return products.cast<Product?>().firstWhere(
    (p) {
      final pcode = p?.code ?? '';
      if (pcode == productKey) return true;
      try {
        final idFromCode = int.parse(productKey);
        if (p?.id == idFromCode) return true;
      } catch (_) {}
      if (pcode.endsWith(productKey)) return true;
      return false;
    },
    orElse: () => null,
  );
}

/// EAN-13 de balanza: prefijo 20/21, PLU en [2..7), peso en gramos en [7..12).
WeightBarcodeResult? parseWeightBarcode(String code, List<Product> products) {
  final parsed = tryParseWeightBarcode(code);
  if (parsed == null) return null;

  final found = matchWeightedProductLocal(products, parsed.productKey);
  if (found == null) return null;

  return WeightBarcodeResult(
    product: found,
    weightKg: parsed.weightKg,
    calculatedUnitPrice: calculateWeightedLineTotal(found, parsed.weightKg),
  );
}

bool isProductWeighted(Product product) {
  return product.isWeighted.toUpperCase() == 'S';
}

/// Precio de lista se trata como $/kg cuando el producto tiene netWeight configurado.
double calculateWeightedLineTotal(Product product, double weightKg) {
  final pricePerKg = product.netWeight > 0 ? (product.price ?? 0.0) : 0.0;
  return pricePerKg * weightKg;
}
