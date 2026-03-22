import 'package:punto_venta_app/core/utils/extensions.dart';
import 'package:punto_venta_app/features/pos/domain/entities/print_job.dart';

/// Clase base abstracta para todos los templates de tickets
abstract class BaseTicketTemplate {
  static const int lineWidth = 48;

  final PrintJob printJob;

  BaseTicketTemplate({required this.printJob});

  /// Método principal que construye el ticket completo
  List<TicketCommand> build();

  // === MÉTODOS COMUNES PARA TODOS LOS TEMPLATES ===

  /// Construye el encabezado del ticket
  /// Si isValidInvoice=true e incluye datos fiscales, muestra información fiscal completa
  List<TicketCommand> buildHeader({bool isValidInvoice = false}) {
    final commands = <TicketCommand>[];
    
    commands.add(TicketCommand.alignment(TicketAlignment.center));
    
    // Si es factura válida y tenemos datos fiscales, mostrar encabezado fiscal
    if (isValidInvoice && printJob.fiscalIssuerData != null) {
      final fiscalData = printJob.fiscalIssuerData!;
      
      // Nombre fiscal
      if (fiscalData.fiscalName != null) {
        commands.add(TicketCommand.bold(true));
        commands.add(TicketCommand.text(fiscalData.fiscalName!));
        commands.add(TicketCommand.bold(false));
        commands.add(TicketCommand.feedLine());
      }
      
      // CUIT
      if (fiscalData.cuit != null) {
        commands.add(TicketCommand.text("C.U.I.T. Nro.: ${fiscalData.cuit!}"));
        commands.add(TicketCommand.feedLine());
      }
      
      // Ingresos Brutos
      if (fiscalData.iibbCuit != null) {
        commands.add(TicketCommand.text("Ing. Brutos: ${fiscalData.iibbCuit!}"));
        commands.add(TicketCommand.feedLine());
      }
      
      // Dirección
      if (fiscalData.address != null) {
        commands.add(TicketCommand.text("Domicilio: ${fiscalData.address!}"));
        commands.add(TicketCommand.feedLine());
      }
      
      // Inicio de actividades
      if (fiscalData.activityStartDate != null) {
        commands.add(TicketCommand.text("Inicio de Actividades: ${fiscalData.activityStartDate!}"));
        commands.add(TicketCommand.feedLine());
      }
      
      // Condición IVA
      if (fiscalData.vatCondition != null) {
        commands.add(TicketCommand.text(fiscalData.vatCondition!));
        commands.add(TicketCommand.feedLine());
      }
      
      // Separador
      commands.add(TicketCommand.feedLine());
      commands.add(TicketCommand.text(buildSeparator('=')));
      commands.add(TicketCommand.feedLine());
      
      // Documento válido como factura
      commands.add(TicketCommand.bold(true));
      commands.add(TicketCommand.text("DOCUMENTO VALIDO COMO FACTURA"));
      commands.add(TicketCommand.bold(false));
      commands.add(TicketCommand.feedLine());
      commands.add(TicketCommand.text(buildSeparator('=')));
      
    } else {
      // Encabezado simple (para templates standard y blackMarket)
      commands.add(TicketCommand.bold(true));
      commands.add(TicketCommand.text("${printJob.enterprise?.name}"));
      commands.add(TicketCommand.bold(false));
      commands.add(TicketCommand.feedLine());
      
      if (!isValidInvoice) {
        // Para operaciones en negro (blackMarket), mostrar mensaje más prominente
        commands.add(TicketCommand.feedLine());
        commands.add(TicketCommand.text(buildSeparator('=')));
        commands.add(TicketCommand.feedLine());
        commands.add(TicketCommand.bold(true));
        commands.add(TicketCommand.text("DOCUMENTO NO VALIDO"));
        commands.add(TicketCommand.feedLine());
        commands.add(TicketCommand.text("COMO FACTURA"));
        commands.add(TicketCommand.bold(false));
        commands.add(TicketCommand.feedLine());
        commands.add(TicketCommand.text(buildSeparator('=')));
      } else {
        // Para factura sin datos fiscales detallados
        commands.add(TicketCommand.text("Sistema de Punto de Venta"));
        commands.add(TicketCommand.feedLine());
        commands.add(TicketCommand.text("Factura"));
        commands.add(TicketCommand.feedLine());
        commands.add(TicketCommand.feedLine());
        commands.add(TicketCommand.text(buildSeparator('_')));
      }
    }
    
    commands.add(TicketCommand.feedLine());
    commands.add(TicketCommand.feedLine());
    
    return commands;
  }

  /// Construye la información de la orden
  List<TicketCommand> buildOrderInfo() {
    final commands = <TicketCommand>[
      TicketCommand.alignment(TicketAlignment.left),
      TicketCommand.text("Orden: ${printJob.ticketId}"),
      TicketCommand.feedLine(),
      TicketCommand.text("Fecha: ${formatDate(printJob.timestamp)}"),
      TicketCommand.feedLine(),
      TicketCommand.text("Hora: ${formatTime(printJob.timestamp)}"),
      TicketCommand.feedLine(),
      TicketCommand.text("Cajero: ${printJob.cashierName}"),
      TicketCommand.feedLine(),
    ];

    if (printJob.clientName != null && printJob.clientName!.isNotEmpty) {
      commands.add(TicketCommand.text("Cliente: ${printJob.clientName}"));
      commands.add(TicketCommand.feedLine());
    }

    commands.add(TicketCommand.text(buildSeparator('_')));
    commands.add(TicketCommand.feedLine());
    commands.add(TicketCommand.feedLine());

    return commands;
  }

  /// Construye la sección de ítems con control sobre mostrar precios con o sin IVA
  List<TicketCommand> buildItemsDetailed({required bool showPricesWithTax}) {
    final commands = <TicketCommand>[];

    commands.add(TicketCommand.text(buildSeparator('=')));
    commands.add(TicketCommand.feedLine());
    commands.add(TicketCommand.bold(true));
    commands.add(TicketCommand.text("ARTICULOS"));
    commands.add(TicketCommand.feedLine());
    commands.add(TicketCommand.bold(false));
    commands.add(TicketCommand.text(buildSeparator('=')));
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
            ? calculatePriceWithTax(basePrice, item.product.vat)
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
            ? calculatePriceWithTax(basePrice, item.product.vat)
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

    commands.add(TicketCommand.text(buildSeparator('-')));
    commands.add(TicketCommand.feedLine());

    return commands;
  }

  /// Construye totales con desglose completo de impuestos
  List<TicketCommand> buildDetailedTotals() {
    final commands = <TicketCommand>[];

    // Calcular subtotal restando todos los impuestos
    final subtotalAmount = (printJob.total - 
        printJob.totalTax - 
        printJob.iibbTax - 
        printJob.vatPerception -
        printJob.internalTax).formatToCurrency();

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

    commands.add(TicketCommand.text(buildSeparator('_')));
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
    commands.add(TicketCommand.text(buildSeparator('_')));
    commands.add(TicketCommand.feedLine());

    return commands;
  }

  /// Construye totales simplificados sin desglose de impuestos
  List<TicketCommand> buildSimplifiedTotals() {
    final commands = <TicketCommand>[];

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
    commands.add(TicketCommand.text(buildSeparator('_')));
    commands.add(TicketCommand.feedLine());

    return commands;
  }

  /// Construye la información adicional del ticket
  List<TicketCommand> buildAdditionalInfo() {
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

  /// Construye el código de barras
  List<TicketCommand> buildBarcode() {
    return [
      TicketCommand.alignment(TicketAlignment.center),
      TicketCommand.barcode(printJob.ticketId ?? ''),
      TicketCommand.feedLine(),
      TicketCommand.feedLine(),
    ];
  }

  /// Construye el pie de página
  List<TicketCommand> buildFooter() {
    return [
      TicketCommand.text("Gracias por su compra!"),
      TicketCommand.feedLine(),
      TicketCommand.feedLine(),
      TicketCommand.feedLine(),
      TicketCommand.cutPaper(),
    ];
  }

  // === UTILIDADES ===

  String buildSeparator(String char) {
    return char * lineWidth;
  }

  String formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  String formatTime(DateTime date) {
    return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}";
  }

  double calculatePriceWithTax(double price, double? taxPercentage) {
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
