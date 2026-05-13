import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:barcode/barcode.dart';
import 'package:punto_venta_app/features/pos/domain/entities/product.dart';
import 'package:punto_venta_app/core/utils/extensions.dart';
import 'dart:typed_data';

class LabelImageBuilder {
  static Future<Uint8List> buildProductLabelImage(Product product) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    
    // Tamaño de la etiqueta (80mm x ~32mm -> 576 x 230 puntos aprox)
    // Ajustado para coincidir con la proporción del script de python (700x205)
    // 576 / (700/205) = 168.
    const double width = 576;
    const double height = 180;
    
    // Fondo blanco
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, width, height),
      Paint()..color = Colors.white,
    );

    const textStyleBig = TextStyle(
      color: Colors.black,
      fontSize: 36,
      fontWeight: ui.FontWeight.bold,
    );
    
    const textStyleSmall = TextStyle(
      color: Colors.black,
      fontSize: 22,
    );
    
    const textStylePrice = TextStyle(
      color: Colors.black,
      fontSize: 58,
      fontWeight: ui.FontWeight.bold,
    );

    // 1. Nombre del producto (Máximo 2 líneas)
    final name = product.name.toUpperCase();
    final textPainter = TextPainter(
      text: const TextSpan(text: '', style: textStyleBig), // Dummy for now
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '...',
    );
    
    // Usamos el textPainter real con el nombre
    textPainter.text = TextSpan(text: name, style: textStyleBig);
    textPainter.layout(maxWidth: width - 20);
    textPainter.paint(canvas, const Offset(10, 5));
    
    double yPrice = 5 + textPainter.height + 10;
    if (yPrice < 70) yPrice = 70; // Asegurar espacio si el nombre es corto

    // 2. Precio
    final basePrice = product.price ?? 0.0;
    final vatPercent = product.vat;
    final priceWithVat = basePrice + (basePrice * (vatPercent / 100));
    
    final pricePainter = TextPainter(
      text: TextSpan(text: priceWithVat.formatToCurrency(), style: textStylePrice),
      textDirection: TextDirection.ltr,
    );
    pricePainter.layout();
    pricePainter.paint(canvas, Offset(10, yPrice));

    // 3. Código de barras
    if (product.barcodes != null && product.barcodes!.isNotEmpty) {
      final barcodeString = product.barcodes!.first.barcode.toString();
      try {
        final bc = Barcode.code128();
        
        // Dibujar barras del código
        const bcWidth = 280.0;
        const bcHeight = 70.0;
        final bcX = width - bcWidth - 10;
        final bcY = yPrice + 5;
        
        // Usamos bc.make para obtener los elementos y dibujarlos
        for (var element in bc.make(barcodeString, width: bcWidth, height: bcHeight)) {
          if (element is BarcodeBar && element.black) {
            canvas.drawRect(
              Rect.fromLTWH(bcX + element.left, bcY + element.top, element.width, element.height),
              Paint()..color = Colors.black,
            );
          }
        }
        
        // Texto del código de barras (opcional, el script lo pone abajo)
        final bcTextPainter = TextPainter(
          text: TextSpan(text: barcodeString, style: textStyleSmall.copyWith(fontSize: 16)),
          textDirection: TextDirection.ltr,
        );
        bcTextPainter.layout();
        bcTextPainter.paint(canvas, Offset(bcX + (bcWidth - bcTextPainter.width) / 2, bcY + bcHeight + 2));
      } catch (e) {
        // Ignorar errores de código de barras
      }
    }

    // 4. Info inferior (ID y Precio sin impuestos)
    final footerY = height - 55;
    
    final idPainter = TextPainter(
      text: TextSpan(text: "Cod: ${product.id}", style: textStyleSmall),
      textDirection: TextDirection.ltr,
    );
    idPainter.layout();
    idPainter.paint(canvas, Offset(10, footerY));

    final sinImpPainter = TextPainter(
      text: TextSpan(text: "Precio sin imp: ${basePrice.formatToCurrency()}", style: textStyleSmall),
      textDirection: TextDirection.ltr,
    );
    sinImpPainter.layout();
    sinImpPainter.paint(canvas, Offset(10, footerY + 25));

    // 5. Fecha
    final dateStr = _formatDate(DateTime.now());
    final datePainter = TextPainter(
      text: TextSpan(text: dateStr, style: textStyleSmall),
      textDirection: TextDirection.ltr,
    );
    datePainter.layout();
    datePainter.paint(canvas, Offset(width - datePainter.width - 10, footerY + 25));

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
    
    return pngBytes!.buffer.asUint8List();
  }

  static String _formatDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    return '$dd/$mm/$yyyy';
  }
}
