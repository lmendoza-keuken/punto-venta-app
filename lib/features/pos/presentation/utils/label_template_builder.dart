import 'package:punto_venta_app/core/utils/extensions.dart';
import 'package:punto_venta_app/features/pos/domain/entities/product.dart';
import 'package:punto_venta_app/features/pos/presentation/utils/templates/base_ticket_template.dart';

/// Builder para etiquetas de góndola de productos
class LabelTemplateBuilder {
  // Para dejar un margen derecho de ~2cm (en impresora 80mm, 48 chars, 2cm ≈ 14 chars)
  static const int _maxLineChars = 34;

  static String _truncateLine(String text) {
    if (text.length > _maxLineChars) {
      return text.substring(0, _maxLineChars);
    }
    return text;
  }

  static const int _nameMaxChars = 28;

  /// Construye una etiqueta para un producto
  static List<TicketCommand> buildProductLabel(Product product) {
    final commands = <TicketCommand>[];

    final basePrice = product.price ?? 0.0;
    final vatPercent = product.vat;
    final priceWithVat = basePrice + (basePrice * (vatPercent / 100));

    final date = _formatDate(DateTime.now());


    // ===== NOMBRE PRODUCTO =====
    commands.add(TicketCommand.alignment(TicketAlignment.left));
    commands.add(TicketCommand.bold(true));

    final normalizedName =
        product.name.toUpperCase().replaceAll(RegExp(r'\s+'), ' ').trim();
    final nameLines = _wrapText(normalizedName, _nameMaxChars).take(2).toList();

    for (final line in nameLines) {
      commands.add(TicketCommand.text(_truncateLine(line)));
      commands.add(TicketCommand.feedLine());
    }
    commands.add(TicketCommand.bold(false));

    // ===== FILA PRECIO =====
    commands.add(TicketCommand.alignment(TicketAlignment.left));
    commands.add(TicketCommand.bold(true));
    commands.add(TicketCommand.textSize(width: 3, height: 4));
    commands.add(TicketCommand.text(priceWithVat.formatToCurrency()));
    commands.add(TicketCommand.textSize(width: 1, height: 1));
    commands.add(TicketCommand.feedLine());
    commands.add(TicketCommand.bold(false));

    // ===== PIE =====
    commands.add(TicketCommand.alignment(TicketAlignment.left));
    commands.add(TicketCommand.text(_truncateLine('Cod: ${product.id}  $date')));
    commands.add(TicketCommand.feedLine());


    // ===== CODIGO DE BARRAS =====
    if (product.barcodes != null && product.barcodes!.isNotEmpty) {
      final barcode = product.barcodes!.first.barcode.toString().trim();

      commands.add(TicketCommand.alignment(TicketAlignment.left));
      commands.add(TicketCommand.setBarcodeWidth(4)); // ancho 
      commands.add(TicketCommand.setBarcodeHeight(32)); // altura 
      commands.add(TicketCommand.setBarcodeHRIPosition(2)); // texto debajo
      commands.add(
          TicketCommand.barcodeWithType(barcode, 67)); // EAN-13 por defecto
    }

    commands.add(TicketCommand.feedLine());
    commands.add(TicketCommand.cutPaper());

    return commands;
  }

  /// Divide un texto largo en líneas que caben en el ancho especificado
  static List<String> _wrapText(String text, int maxWidth) {
    if (text.length <= maxWidth) return [text];

    final lines = <String>[];
    var currentLine = '';
    final words = text.split(' ');

    for (final word in words) {
      if (currentLine.isEmpty) {
        currentLine = word;
      } else if ((currentLine.length + 1 + word.length) <= maxWidth) {
        currentLine += ' $word';
      } else {
        lines.add(currentLine.trim());
        currentLine = word;
      }
    }

    if (currentLine.isNotEmpty) lines.add(currentLine.trim());
    return lines;
  }

  static String _formatDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    return '$dd/$mm/$yyyy';
  }
}
