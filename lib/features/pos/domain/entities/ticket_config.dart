/// Configuracion de tickets
class TicketConfig {
  final String id;
  final bool showSubtotalAndTax;
  final bool showPricesWithTax;
  final DateTime lastUpdated;

  const TicketConfig({
    required this.id,
    required this.showSubtotalAndTax,
    required this.showPricesWithTax,
    required this.lastUpdated,
  });

  TicketConfig copyWith({
    String? id,
    bool? showSubtotalAndTax,
    bool? showPricesWithTax,
    DateTime? lastUpdated,
  }) {
    return TicketConfig(
      id: id ?? this.id,
      showSubtotalAndTax: showSubtotalAndTax ?? this.showSubtotalAndTax,
      showPricesWithTax: showPricesWithTax ?? this.showPricesWithTax,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
