import 'package:punto_venta_app/core/constants/ticket_template_types.dart';

class TicketTemplateResolver {
  /// Determina el template a usar según:
  /// - Sucursal (branchAfipAvailable): true=whiteMarket (blanco), false=blackMarket (negro)
  /// - Cliente (clientTaxDetails): controla si whiteMarket muestra desglose
  static TicketTemplateType resolveTemplate({
    bool? branchAfipAvailable,
  }) {
    // Si la sucursal NO tiene AFIP disponible → operación en NEGRO (sin factura)
    if (branchAfipAvailable == false) {
      return TicketTemplateType.blackMarket;
    }

    // Si la sucursal tiene AFIP disponible → operación en BLANCO (con factura)
    // El desglose se controla con showSubtotalAndTax basado en tax_details
    if (branchAfipAvailable == true) {
      return TicketTemplateType.whiteMarket;
    }

    // Si no hay información, usar estándar
    return TicketTemplateType.standard;
  }

  /// Determina si se deben mostrar los precios con IVA según el template
  static bool shouldShowPricesWithTax({
    required TicketTemplateType templateType,
    bool? clientTaxDetails,
  }) {
    switch (templateType) {
      case TicketTemplateType.blackMarket:
        // Operación en negro: precios con IVA incluido
        return true;
      case TicketTemplateType.whiteMarket:
        // Operación en blanco: si tiene desglose (tax_details=true), precios sin IVA
        // Si no tiene desglose (tax_details=false), precios con IVA
        return clientTaxDetails == false;
      case TicketTemplateType.standard:
        return true;
    }
  }

  static bool shouldShowSubtotalAndTax({
    required TicketTemplateType templateType,
    bool? clientTaxDetails,
    bool hasClient = false,
  }) {
    if (!hasClient) {
      return false;
    }

    switch (templateType) {
      case TicketTemplateType.blackMarket:
        // Operación en negro: nunca muestra desglose
        return false;
      case TicketTemplateType.whiteMarket:
        // Operación en blanco: muestra desglose solo si tax_details=true
        return clientTaxDetails == true;
      case TicketTemplateType.standard:
        return false;
    }
  }
}
