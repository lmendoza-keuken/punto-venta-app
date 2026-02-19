import 'package:punto_venta_app/features/pos/domain/entities/ticket_config.dart';

class TicketConfigModel {
  final String id;
  final bool showSubtotalAndTax;
  final bool showPricesWithTax;
  final DateTime lastUpdated;

  const TicketConfigModel({
    required this.id,
    required this.showSubtotalAndTax,
    required this.showPricesWithTax,
    required this.lastUpdated,
  });

  factory TicketConfigModel.fromJson(Map<String, dynamic> json) {
    return TicketConfigModel(
      id: json['id']?.toString() ?? '',
      showSubtotalAndTax:
          json['show_subtotal_and_tax'] ?? json['showSubtotalAndTax'] ?? false,
      showPricesWithTax:
          json['show_prices_with_tax'] ?? json['showPricesWithTax'] ?? true,
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'])
          : json['lastUpdated'] != null
              ? DateTime.parse(json['lastUpdated'])
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    final map = {
      'id': id,
      'show_subtotal_and_tax': showSubtotalAndTax,
      'show_prices_with_tax': showPricesWithTax,
      'last_updated': lastUpdated.toIso8601String(),
    };

    return map;
  }

  factory TicketConfigModel.fromEntity(TicketConfig entity) {
    return TicketConfigModel(
      id: entity.id,
      showSubtotalAndTax: entity.showSubtotalAndTax,
      showPricesWithTax: entity.showPricesWithTax,
      lastUpdated: entity.lastUpdated,
    );
  }

  TicketConfig toEntity() {
    return TicketConfig(
      id: id,
      showSubtotalAndTax: showSubtotalAndTax,
      showPricesWithTax: showPricesWithTax,
      lastUpdated: lastUpdated,
    );
  }

  Map<String, dynamic> toMap() {
    final map = {
      'id': id,
      'showSubtotalAndTax': showSubtotalAndTax ? 1 : 0,
      'showPricesWithTax': showPricesWithTax ? 1 : 0,
      'lastUpdated': lastUpdated.toIso8601String(),
    };

    return map;
  }

  factory TicketConfigModel.fromMap(Map<String, dynamic> map) {
    return TicketConfigModel(
      id: map['id']?.toString() ?? '',
      showSubtotalAndTax: map['showSubtotalAndTax'] == 1,
      showPricesWithTax: map['showPricesWithTax'] == 1,
      lastUpdated: DateTime.parse(map['lastUpdated']),
    );
  }
}
