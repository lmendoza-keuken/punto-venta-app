import 'package:punto_venta_app/core/constants/ticket_template_types.dart';
import 'package:punto_venta_app/core/utils/extensions.dart';
import 'package:punto_venta_app/features/pos/domain/entities/print_job.dart';

class TicketTemplateBuilder {
  static const int lineWidth = 48;

  final PrintJob printJob;

  TicketTemplateBuilder({
    required this.printJob,
  });

  /// Construye el contenido del ticket en formato de lista de comandos
  /// según el template configurado
  List<TicketCommand> build() {
    switch (printJob.templateType) {
      case TicketTemplateType.standard:
        return _buildStandardTemplate();
      case TicketTemplateType.blackMarket:
        return _buildBlackMarketTemplate();
      case TicketTemplateType.whiteMarket:
        return _buildWhiteMarketTemplate();
    }
  }

  /// Template estándar (actual implementación)
  List<TicketCommand> _buildStandardTemplate() {
    final commands = <TicketCommand>[];

    // === ENCABEZADO ===
    commands.addAll(_buildHeader());

    // === INFORMACIÓN DE LA ORDEN ===
    commands.addAll(_buildOrderInfo());

    // === ITEMS ===
    commands.addAll(_buildItems());

    // === TOTALES ===
    commands.addAll(_buildTotals());

    // === INFORMACIÓN ADICIONAL ===
    commands.addAll(_buildAdditionalInfo());

    // === CÓDIGO DE BARRAS ===
    commands.addAll(_buildBarcode());

    // === PIE DE PÁGINA ===
    commands.addAll(_buildFooter());

    return commands;
  }

  /// Template para operación en NEGRO (sin factura fiscal)
  /// Se usa cuando: afip_available=false
  /// Formato: precios con IVA incluido, sin desglose de impuestos
  List<TicketCommand> _buildBlackMarketTemplate() {
    final commands = <TicketCommand>[];

    // === ENCABEZADO ===
    commands.addAll(_buildHeader());

    // === INFORMACIÓN DE LA ORDEN ===
    commands.addAll(_buildOrderInfo());

    // === ITEMS ===
    // En blackMarket mostramos precios con IVA incluido para simplicidad
    commands.addAll(_buildItemsDetailed(showPricesWithTax: true));

    // === TOTALES SIMPLIFICADOS ===
    commands.addAll(_buildSimplifiedTotals());

    // === INFORMACIÓN ADICIONAL ===
    commands.addAll(_buildAdditionalInfo());

    // === CÓDIGO DE BARRAS ===
    commands.addAll(_buildBarcode());

    // === PIE DE PÁGINA ===
    commands.addAll(_buildFooter());

    return commands;
  }

  /// Template para operación en BLANCO (con factura fiscal)
  /// Se usa cuando: afip_available=true
  /// - Si tax_details=true: muestra desglose completo, precios sin IVA
  /// - Si tax_details=false: sin desglose, precios con IVA
  List<TicketCommand> _buildWhiteMarketTemplate() {
    final commands = <TicketCommand>[];

    // === ENCABEZADO ===
    commands.addAll(_buildHeader());

    // === INFORMACIÓN DE LA ORDEN ===
    commands.addAll(_buildOrderInfo());

    // === ITEMS ===
    // Precios según showPricesWithTax (controlado por tax_details)
    commands.addAll(_buildItemsDetailed(showPricesWithTax: printJob.showPricesWithTax));

    // === TOTALES ===
    // Si showSubtotalAndTax=true (tax_details=true) → desglose completo
    // Si showSubtotalAndTax=false (tax_details=false) → sin desglose
    if (printJob.showSubtotalAndTax) {
      commands.addAll(_buildDetailedTotals());
    } else {
      commands.addAll(_buildSimplifiedTotals());
    }

    // === INFORMACIÓN ADICIONAL ===
    commands.addAll(_buildAdditionalInfo());

    // === CÓDIGO DE BARRAS ===
    commands.addAll(_buildBarcode());

    // === PIE DE PÁGINA ===
    commands.addAll(_buildFooter());

    return commands;
  }

  /// Construye items con control específico sobre mostrar precios con o sin IVA
  List<TicketCommand> _buildItemsDetailed({required bool showPricesWithTax}) {
    final commands = <TicketCommand>[];

    commands.add(TicketCommand.text(_buildSeparator('=')));
    commands.add(TicketCommand.feedLine());
    commands.add(TicketCommand.bold(true));
    commands.add(TicketCommand.text("ARTICULOS"));
    commands.add(TicketCommand.feedLine());
    commands.add(TicketCommand.bold(false));
    commands.add(TicketCommand.text(_buildSeparator('=')));
    commands.add(TicketCommand.feedLine());

    for (var item in printJob.items) {
      final productName = item.product.name.length > lineWidth - 2
          ? item.product.name.substring(0, lineWidth - 5) + "..."
          : item.product.name;

      commands.add(TicketCommand.text(productName));
      commands.add(TicketCommand.feedLine());

      final basePrice = item.product.price ?? 0;

      if (item.isWeighted == true) {
        final unitPrice = showPricesWithTax
            ? _calculatePriceWithTax(basePrice, item.product.vat)
            : basePrice;
        final subtotalValue = (item.quantity * unitPrice).formatToCurrency();
        final line =
            "  ${(item.quantity / 1000).toStringAsFixed(3)} kg x ${unitPrice.formatToCurrency()}";

        final totalSpaces = lineWidth - line.length - subtotalValue.length;
        final spacer = totalSpaces > 0 ? ' ' * totalSpaces : ' ';

        commands.add(TicketCommand.text("$line$spacer$subtotalValue"));
        commands.add(TicketCommand.feedLine());
      } else {
        final displayPrice = showPricesWithTax
            ? _calculatePriceWithTax(basePrice, item.product.vat)
            : basePrice;

        final unitPrice = displayPrice.formatToCurrency();
        final subtotalValue = (item.quantity * displayPrice).formatToCurrency();
        final line = "  ${item.quantity} x $unitPrice";

        final totalSpaces = lineWidth - line.length - subtotalValue.length;
        final spacer = totalSpaces > 0 ? ' ' * totalSpaces : ' ';

        commands.add(TicketCommand.text("$line$spacer$subtotalValue"));
        commands.add(TicketCommand.feedLine());
      }
    }

    commands.add(TicketCommand.text(_buildSeparator('-')));
    commands.add(TicketCommand.feedLine());

    return commands;
  }

  /// Totales con desglose completo de impuestos (para whiteMarket)
  List<TicketCommand> _buildDetailedTotals() {
    final commands = <TicketCommand>[];

    // Calcular subtotal restando todos los impuestos
    final subtotalAmount = (printJob.total - 
        printJob.totalTax - 
        printJob.iibbTax - 
        printJob.vatPerception -
        printJob.internalTax).formatToCurrency();

    // Siempre mostrar subtotal en template whiteMarket (operaciones en blanco con desglose fiscal)
    commands.add(TicketCommand.lineWithValue("Subtotal:", subtotalAmount));

    // Siempre mostrar IVA aunque sea 0
    final taxAmount = printJob.totalTax.formatToCurrency();
    commands.add(TicketCommand.lineWithValue("IVA:", taxAmount));

    // Percepción IIBB si es mayor a 0
    if (printJob.iibbTax > 0) {
      final iibbAmount = printJob.iibbTax.formatToCurrency();
      final iibbLabel = printJob.iibbTaxPercentage != null
          ? "Percep. IIBB (${printJob.iibbTaxPercentage}%):"
          : "Percep. IIBB:";
      commands.add(TicketCommand.lineWithValue(iibbLabel, iibbAmount));
    }

    // Percepción IVA si es mayor a 0
    if (printJob.vatPerception > 0) {
      final vatPercepAmount = printJob.vatPerception.formatToCurrency();
      commands.add(TicketCommand.lineWithValue("Percep. IVA:", vatPercepAmount));
    }

    // Impuesto Interno si es mayor a 0
    if (printJob.internalTax > 0) {
      final internalTaxAmount = printJob.internalTax.formatToCurrency();
      final internalTaxLabel = printJob.internalTaxRate != null && printJob.internalTaxRate! > 0
          ? "Imp. Interno (${printJob.internalTaxRate}%):"
          : "Imp. Interno:";
      commands.add(TicketCommand.lineWithValue(internalTaxLabel, internalTaxAmount));
    }

    commands.add(TicketCommand.text(_buildSeparator('_')));
    commands.add(TicketCommand.feedLine());

    if (printJob.receivedAmount != null && printJob.change != null) {
      final receivedAmount = printJob.receivedAmount!.formatToCurrency();
      final changeAmount = printJob.change!.formatToCurrency();

      commands.add(TicketCommand.feedLine());
      commands.add(TicketCommand.lineWithValue("Recibido:", receivedAmount));
      commands.add(TicketCommand.lineWithValue("Cambio:", changeAmount));
    }

    // Total siempre se muestra
    commands.add(TicketCommand.feedLine());
    commands.add(TicketCommand.bold(true));
    commands.add(TicketCommand.doubleHeight(true));
    commands.add(TicketCommand.lineWithValue(
        "TOTAL:", printJob.total.formatToCurrency()));
    commands.add(TicketCommand.doubleHeight(false));
    commands.add(TicketCommand.bold(false));
    commands.add(TicketCommand.text(_buildSeparator('_')));
    commands.add(TicketCommand.feedLine());

    return commands;
  }

  /// Totales simplificados sin desglose de impuestos (para blackMarket)
  List<TicketCommand> _buildSimplifiedTotals() {
    final commands = <TicketCommand>[];

    // En blackMarket solo mostramos el total directamente (operaciones en negro simplificadas)
    // Los impuestos están incluidos en los precios

    if (printJob.receivedAmount != null && printJob.change != null) {
      final receivedAmount = printJob.receivedAmount!.formatToCurrency();
      final changeAmount = printJob.change!.formatToCurrency();

      commands.add(TicketCommand.lineWithValue("Recibido:", receivedAmount));
      commands.add(TicketCommand.lineWithValue("Cambio:", changeAmount));
      commands.add(TicketCommand.feedLine());
    }

    // Total destacado
    commands.add(TicketCommand.bold(true));
    commands.add(TicketCommand.doubleHeight(true));
    commands.add(TicketCommand.lineWithValue(
        "TOTAL:", printJob.total.formatToCurrency()));
    commands.add(TicketCommand.doubleHeight(false));
    commands.add(TicketCommand.bold(false));
    commands.add(TicketCommand.text(_buildSeparator('_')));
    commands.add(TicketCommand.feedLine());

    return commands;
  }

  List<TicketCommand> _buildHeader() {
    return [
      TicketCommand.alignment(TicketAlignment.center),
      TicketCommand.bold(true),
      TicketCommand.text("${printJob.enterprise?.name}"),
      TicketCommand.feedLine(),
      TicketCommand.bold(false),
      TicketCommand.text("Sistema de Punto de Venta"),
      TicketCommand.feedLine(),
      TicketCommand.text("Comprobante no valido como factura"),
      // TicketCommand.feedLine(),
      // TicketCommand.text("Tel: (555) 123-4567"),
      TicketCommand.feedLine(),
      TicketCommand.feedLine(),
      TicketCommand.text(_buildSeparator('_')),
      TicketCommand.feedLine(),
      TicketCommand.feedLine(),
    ];
  }

  List<TicketCommand> _buildOrderInfo() {
    final commands = <TicketCommand>[
      TicketCommand.alignment(TicketAlignment.left),
      TicketCommand.text("Orden: ${printJob.ticketId}"),
      TicketCommand.feedLine(),
      TicketCommand.text("Fecha: ${_formatDate(printJob.timestamp)}"),
      TicketCommand.feedLine(),
      TicketCommand.text("Hora: ${_formatTime(printJob.timestamp)}"),
      TicketCommand.feedLine(),
      TicketCommand.text("Cajero: ${printJob.cashierName}"),
      TicketCommand.feedLine(),
    ];

    if (printJob.clientName != null && printJob.clientName!.isNotEmpty) {
      commands.add(TicketCommand.text("Cliente: ${printJob.clientName}"));
      commands.add(TicketCommand.feedLine());
    }

    commands.add(TicketCommand.text(_buildSeparator('_')));
    commands.add(TicketCommand.feedLine());
    commands.add(TicketCommand.feedLine());

    return commands;
  }

  List<TicketCommand> _buildItems() {
    final commands = <TicketCommand>[
      TicketCommand.alignment(TicketAlignment.left),
    ];

    for (final item in printJob.items) {
      commands.add(TicketCommand.text(item.product.description));
      commands.add(TicketCommand.feedLine());

      if (item.isWeighted == true) {
        final weightKg = (item.weightKg ?? 0.0);
        final pricePerKg = (item.pricePerKg ?? item.product.price ?? 0.0);

        // Calcular precio con o sin IVA según configuración
        final displayPrice = printJob.showPricesWithTax
            ? _calculatePriceWithTax(pricePerKg, item.product.vat)
            : pricePerKg;

        final subtotal = weightKg * displayPrice;

        final subtotalValue = subtotal.formatToCurrency();
        final weightLabel = "$weightKg kg";
        final priceLabel = displayPrice.formatToCurrency();

        final lineLeft = "  $weightLabel x $priceLabel";
        final totalSpacesLeft =
            lineWidth - lineLeft.length - subtotalValue.length;
        final spacerLeft = totalSpacesLeft > 0 ? ' ' * totalSpacesLeft : ' ';

        commands.add(TicketCommand.text("$lineLeft$spacerLeft$subtotalValue"));
        commands.add(TicketCommand.feedLine());
      } else {
        final basePrice = (item.pricePerKg ?? item.product.price ?? 0.0);

        // Calcular precio con o sin IVA según configuración
        final displayPrice = printJob.showPricesWithTax
            ? _calculatePriceWithTax(basePrice, item.product.vat)
            : basePrice;

        final unitPrice = displayPrice.formatToCurrency();
        final subtotalValue = (item.quantity * displayPrice).formatToCurrency();
        final line = "  ${item.quantity} x $unitPrice";

        final totalSpaces = lineWidth - line.length - subtotalValue.length;
        final spacer = totalSpaces > 0 ? ' ' * totalSpaces : ' ';

        commands.add(TicketCommand.text("$line$spacer$subtotalValue"));
        commands.add(TicketCommand.feedLine());
      }
    }

    commands.add(TicketCommand.text(_buildSeparator('-')));
    commands.add(TicketCommand.feedLine());

    return commands;
  }

  List<TicketCommand> _buildTotals() {
    final commands = <TicketCommand>[];

    // Calcular subtotal restando todos los impuestos
    final subtotalAmount = (printJob.total - 
        printJob.totalTax - 
        printJob.iibbTax - 
        printJob.vatPerception -
        printJob.internalTax).formatToCurrency();

    // Subtotal siempre se muestra
    commands.add(TicketCommand.lineWithValue("Subtotal:", subtotalAmount));

    // IVA si es mayor a 0
    if (printJob.totalTax > 0) {
      final taxAmount = printJob.totalTax.formatToCurrency();
      commands.add(TicketCommand.lineWithValue("IVA:", taxAmount));
    }

    // Percepción IIBB si es mayor a 0
    if (printJob.iibbTax > 0) {
      final iibbAmount = printJob.iibbTax.formatToCurrency();
      final iibbLabel = printJob.iibbTaxPercentage != null
          ? "Percep. IIBB (${printJob.iibbTaxPercentage}%):"
          : "Percep. IIBB:";
      commands.add(TicketCommand.lineWithValue(iibbLabel, iibbAmount));
    }

    // Percepción IVA si es mayor a 0
    if (printJob.vatPerception > 0) {
      final vatPercepAmount = printJob.vatPerception.formatToCurrency();
      commands.add(TicketCommand.lineWithValue("Percep. IVA:", vatPercepAmount));
    }

    // Impuesto Interno si es mayor a 0
    if (printJob.internalTax > 0) {
      final internalTaxAmount = printJob.internalTax.formatToCurrency();
      final internalTaxLabel = printJob.internalTaxRate != null && printJob.internalTaxRate! > 0
          ? "Imp. Interno (${printJob.internalTaxRate}%):"
          : "Imp. Interno:";
      commands.add(TicketCommand.lineWithValue(internalTaxLabel, internalTaxAmount));
    }

    commands.add(TicketCommand.text(_buildSeparator('_')));
    commands.add(TicketCommand.feedLine());

    if (printJob.receivedAmount != null && printJob.change != null) {
      final receivedAmount = printJob.receivedAmount!.formatToCurrency();
      final changeAmount = printJob.change!.formatToCurrency();

      commands.add(TicketCommand.feedLine());
      commands.add(TicketCommand.lineWithValue("Recibido:", receivedAmount));
      commands.add(TicketCommand.lineWithValue("Cambio:", changeAmount));
    }

    // Total siempre se muestra
    commands.add(TicketCommand.feedLine());
    commands.add(TicketCommand.bold(true));
    commands.add(TicketCommand.doubleHeight(true));
    commands.add(TicketCommand.lineWithValue(
        "TOTAL:", printJob.total.formatToCurrency()));
    commands.add(TicketCommand.doubleHeight(false));
    commands.add(TicketCommand.bold(false));
    commands.add(TicketCommand.text(_buildSeparator('_')));
    commands.add(TicketCommand.feedLine());

    return commands;
  }

  List<TicketCommand> _buildAdditionalInfo() {
    final totalItems =
        printJob.items.fold(0, (sum, item) => sum + item.quantity);

    return [
      TicketCommand.feedLine(),
      TicketCommand.text(
          "Metodo de pago: ${printJob.paymentMethod?.shortDescription ?? 'Efectivo'}"),
      TicketCommand.feedLine(),
      TicketCommand.text("Total de articulos: $totalItems"),
      TicketCommand.feedLine(),
      TicketCommand.feedLine(),
    ];
  }

  List<TicketCommand> _buildBarcode() {
    return [
      TicketCommand.alignment(TicketAlignment.center),
      TicketCommand.barcode(printJob.ticketId ?? ''),
      TicketCommand.feedLine(),
      TicketCommand.feedLine(),
    ];
  }

  List<TicketCommand> _buildFooter() {
    return [
      TicketCommand.text("Gracias por su compra!"),
      TicketCommand.feedLine(),
      TicketCommand.feedLine(),
      TicketCommand.feedLine(),
      TicketCommand.cutPaper(),
    ];
  }

  // === UTILIDADES ===

  String _buildSeparator(String char) {
    return char * lineWidth;
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  String _formatTime(DateTime date) {
    return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}";
  }

  double _calculatePriceWithTax(double price, double? taxPercentage) {
    final tax = (taxPercentage ?? 0.0) / 100;
    return price * (1 + tax);
  }
}

// === COMANDOS DEL TICKET ===

enum TicketAlignment { left, center, right }

class TicketCommand {
  final TicketCommandType type;
  final dynamic value;

  TicketCommand._(this.type, [this.value]);

  factory TicketCommand.text(String text) =>
      TicketCommand._(TicketCommandType.text, text);
  factory TicketCommand.feedLine() =>
      TicketCommand._(TicketCommandType.feedLine);
  factory TicketCommand.alignment(TicketAlignment align) =>
      TicketCommand._(TicketCommandType.alignment, align);
  factory TicketCommand.bold(bool enable) =>
      TicketCommand._(TicketCommandType.bold, enable);
  factory TicketCommand.doubleHeight(bool enable) =>
      TicketCommand._(TicketCommandType.doubleHeight, enable);
  factory TicketCommand.barcode(String code) =>
      TicketCommand._(TicketCommandType.barcode, code);
  factory TicketCommand.cutPaper() =>
      TicketCommand._(TicketCommandType.cutPaper);
  factory TicketCommand.lineWithValue(String label, String value) =>
      TicketCommand._(
          TicketCommandType.lineWithValue, {'label': label, 'value': value});
}

enum TicketCommandType {
  text,
  feedLine,
  alignment,
  bold,
  doubleHeight,
  barcode,
  cutPaper,
  lineWithValue,
}
