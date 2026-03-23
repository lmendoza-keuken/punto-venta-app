import 'package:punto_venta_app/features/pos/domain/entities/product.dart';
import 'package:punto_venta_app/features/pos/presentation/utils/templates/base_ticket_template.dart';

/// Builder para etiquetas de góndola de productos
class LabelTemplateBuilder {
  static const int lineWidth = 48;

  /// Construye una etiqueta para un producto
  static List<TicketCommand> buildProductLabel(Product product) {
    final commands = <TicketCommand>[];


    // === NOMBRE DEL PRODUCTO ===
    commands.add(TicketCommand.alignment(TicketAlignment.center));
    commands.add(TicketCommand.bold(true));
    final productName = product.name;
    final nameLines = _wrapText(productName, lineWidth);
    for (final line in nameLines) {
      commands.add(TicketCommand.text(line));
      commands.add(TicketCommand.feedLine());
    }
    commands.add(TicketCommand.bold(false));
    commands.add(TicketCommand.feedLine());

    // === PRECIO ===
    // Calcular precio con IVA
    final priceWithVat = ((product.price ?? 0) * (product.vat / 100)) + (product.price ?? 0);
    
    commands.add(TicketCommand.bold(true));
    commands.add(TicketCommand.doubleHeight(true));
    final priceText = priceWithVat.toStringAsFixed(2);
    commands.add(TicketCommand.text("\$ $priceText"));
    commands.add(TicketCommand.doubleHeight(false));
    commands.add(TicketCommand.bold(false));
    commands.add(TicketCommand.feedLine());
    commands.add(TicketCommand.feedLine());

    // === CÓDIGO DE BARRAS ===
    if (product.barcodes != null && product.barcodes!.isNotEmpty) {
      final firstBarcode = product.barcodes!.first.barcode.toString();
      
      // Configurar código de barras
      commands.add(TicketCommand.setBarcodeHeight(60));
      commands.add(TicketCommand.setBarcodeHRIPosition(0));

      final barcodeType = firstBarcode.length == 13 ? 67 : 69;
      commands.add(TicketCommand.barcodeWithType(firstBarcode, barcodeType));
      commands.add(TicketCommand.feedLine());
      
      // Código de barras y código de producto en la misma línea
      commands.add(TicketCommand.alignment(TicketAlignment.center));
      commands.add(TicketCommand.text("$firstBarcode  Cod: ${product.id}"));
      commands.add(TicketCommand.feedLine());
    }

    commands.add(TicketCommand.feedLine());
    commands.add(TicketCommand.feedLine());

    // === CORTE DE PAPEL ===
    commands.add(TicketCommand.cutPaper());

    return commands;
  }

  /// Divide un texto largo en líneas que caben en el ancho especificado
  static List<String> _wrapText(String text, int maxWidth) {
    if (text.length <= maxWidth) {
      return [text];
    }

    final lines = <String>[];
    var currentLine = '';
    final words = text.split(' ');

    for (final word in words) {
      if (currentLine.isEmpty) {
        currentLine = word;
      } else if ((currentLine.length + word.length + 1) <= maxWidth) {
        currentLine += ' $word';
      } else {
        lines.add(currentLine);
        currentLine = word;
      }
    }

    if (currentLine.isNotEmpty) {
      lines.add(currentLine);
    }

    return lines;
  }
}
