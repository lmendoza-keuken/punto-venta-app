/// Configuración de punto de venta (Sucursal/PDV)
class AppConfig {
  final String id;
  final bool showSubtotalAndTax;
  final bool showPricesWithTax;
  final DateTime lastUpdated;

  const AppConfig({
    required this.id,
    required this.showSubtotalAndTax,
    required this.showPricesWithTax,
    required this.lastUpdated,
  });

  AppConfig copyWith({
    String? id,
    bool? showSubtotalAndTax,
    bool? showPricesWithTax,
    DateTime? lastUpdated,
  }) {
    return AppConfig(
      id: id ?? this.id,
      showSubtotalAndTax: showSubtotalAndTax ?? this.showSubtotalAndTax,
      showPricesWithTax: showPricesWithTax ?? this.showPricesWithTax,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
