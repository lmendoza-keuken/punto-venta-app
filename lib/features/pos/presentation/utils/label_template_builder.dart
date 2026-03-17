import 'package:punto_venta_app/features/pos/domain/entities/product.dart';
import 'package:punto_venta_app/features/pos/presentation/utils/ticket_template_builder.dart';

/// Builder para etiquetas de góndola de productos
class LabelTemplateBuilder {
  static const int lineWidth = 48;

  /// Construye una etiqueta para un producto
  static List<TicketCommand> buildProductLabel(Product product) {
    final commands = <TicketCommand>[];

    // === ENCABEZADO ===
    commands.add(TicketCommand.alignment(TicketAlignment.center));
    commands.add(TicketCommand.bold(true));
    commands.add(TicketCommand.doubleHeight(true));
    commands.add(TicketCommand.text("ETIQUETA DE PRODUCTO"));
    commands.add(TicketCommand.doubleHeight(false));
    commands.add(TicketCommand.bold(false));
    commands.add(TicketCommand.feedLine());
    commands.add(TicketCommand.text(_buildSeparator('=')));
    commands.add(TicketCommand.feedLine());
    commands.add(TicketCommand.feedLine());

    // === NOMBRE DEL PRODUCTO ===
    commands.add(TicketCommand.alignment(TicketAlignment.left));
    commands.add(TicketCommand.bold(true));
    commands.add(TicketCommand.text("PRODUCTO:"));
    commands.add(TicketCommand.bold(false));
    commands.add(TicketCommand.feedLine());
    
    // Dividir nombre largo en varias líneas si es necesario
    final productName = product.name;
    final nameLines = _wrapText(productName, lineWidth - 2);
    for (final line in nameLines) {
      commands.add(TicketCommand.text("  $line"));
      commands.add(TicketCommand.feedLine());
    }
    commands.add(TicketCommand.feedLine());

    // === CÓDIGO DEL ARTÍCULO ===
    commands.add(TicketCommand.bold(true));
    commands.add(TicketCommand.text("CÓDIGO:"));
    commands.add(TicketCommand.bold(false));
    commands.add(TicketCommand.text(" ${product.id}"));
    commands.add(TicketCommand.feedLine());
    commands.add(TicketCommand.feedLine());

    // === PRECIO ===
    commands.add(TicketCommand.alignment(TicketAlignment.center));
    
    // Calcular precio con IVA (igual que en POS)
    final priceWithVat = ((product.price ?? 0) * (product.vat / 100)) + (product.price ?? 0);
    final regularPriceWithVat = product.regularPrice != null 
        ? ((product.regularPrice! * (product.vat / 100)) + product.regularPrice!)
        : null;
    
    // Si hay oferta, mostrar precio regular y descuento
    if (product.isOnSale && regularPriceWithVat != null && regularPriceWithVat > 0) {
      // Precio regular
      commands.add(TicketCommand.bold(true));
      commands.add(TicketCommand.text("PRECIO REGULAR"));
      commands.add(TicketCommand.bold(false));
      commands.add(TicketCommand.feedLine());
      
      commands.add(TicketCommand.bold(true));
      final regularPriceText = "\$ ${regularPriceWithVat.toStringAsFixed(2)}";
      commands.add(TicketCommand.text(regularPriceText));
      commands.add(TicketCommand.bold(false));
      commands.add(TicketCommand.feedLine());
      commands.add(TicketCommand.feedLine());
      
      // Descuento
      final discountPercentage = (((regularPriceWithVat - priceWithVat) / regularPriceWithVat) * 100).toStringAsFixed(0);
      commands.add(TicketCommand.bold(true));
      commands.add(TicketCommand.text("DESCUENTO: -$discountPercentage%"));
      commands.add(TicketCommand.bold(false));
      commands.add(TicketCommand.feedLine());
      commands.add(TicketCommand.feedLine());
      
      // Precio con descuento
      commands.add(TicketCommand.bold(true));
      commands.add(TicketCommand.text("PRECIO DE OFERTA"));
      commands.add(TicketCommand.bold(false));
      commands.add(TicketCommand.feedLine());
    }
    
    commands.add(TicketCommand.bold(true));
    commands.add(TicketCommand.doubleHeight(true));
    final priceText = "\$ ${priceWithVat.toStringAsFixed(2)}";
    commands.add(TicketCommand.text(priceText));
    commands.add(TicketCommand.doubleHeight(false));
    commands.add(TicketCommand.bold(false));
    commands.add(TicketCommand.feedLine());
    
    // Precio sin IVA (informativo)
    final priceNoVat = product.price ?? 0;
    commands.add(TicketCommand.text("\$ ${priceNoVat.toStringAsFixed(2)} SIN IVA"));
    commands.add(TicketCommand.feedLine());
    commands.add(TicketCommand.feedLine());

    // === CÓDIGO DE BARRAS ===
    if (product.barcodes != null && product.barcodes!.isNotEmpty) {
      final firstBarcode = product.barcodes!.first.barcode.toString();
      commands.add(TicketCommand.alignment(TicketAlignment.center));
      commands.add(TicketCommand.text("CÓDIGO DE BARRAS:"));
      commands.add(TicketCommand.feedLine());
      commands.add(TicketCommand.barcode(firstBarcode));
      commands.add(TicketCommand.feedLine());
      commands.add(TicketCommand.text(firstBarcode));
      commands.add(TicketCommand.feedLine());
    }

    // === INFORMACIÓN ADICIONAL ===
    commands.add(TicketCommand.feedLine());
    commands.add(TicketCommand.alignment(TicketAlignment.left));
    commands.add(TicketCommand.text("Categoría: ${product.categoryDescription}"));
    commands.add(TicketCommand.feedLine());

    // === SEPARADOR FINAL ===
    commands.add(TicketCommand.feedLine());
    commands.add(TicketCommand.alignment(TicketAlignment.center));
    commands.add(TicketCommand.text(_buildSeparator('=')));
    commands.add(TicketCommand.feedLine());
    commands.add(TicketCommand.feedLine());
    commands.add(TicketCommand.feedLine());

    // === CORTE DE PAPEL ===
    commands.add(TicketCommand.cutPaper());

    return commands;
  }

  /// Construye un separador con el carácter especificado
  static String _buildSeparator(String char) {
    return char * lineWidth;
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
