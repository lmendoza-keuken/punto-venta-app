import 'dart:io';
import 'dart:ui' as ui;

import 'package:barcode/barcode.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:punto_venta_app/core/utils/extensions.dart';
import 'package:punto_venta_app/features/pos/domain/entities/product.dart';

class LabelImageBuilder {
  static Future<Uint8List> buildProductLabelImage(Product product) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    
    // Tamaño de la etiqueta (80mm x ~32mm -> 576 x 230 puntos aprox)
    // Ajustado para coincidir con la proporción del script de python (700x205)
    // 576 / (700/205) = 168.
    const double width = 576;
    const double height = 314;
    
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
      fontSize: 18,
    );
    
    const textStylePrice = TextStyle(
      color: Colors.black,
      fontSize: 96,
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
    
    double yPrice = textPainter.height + 10;

    // 2. Precio
    final basePrice = product.price ?? 0.0;
    final vatPercent = product.vat;
    final priceWithVat = basePrice + (basePrice * (vatPercent / 100));
    
    final pricePainter = TextPainter(
      text: TextSpan(text: priceWithVat.formatToCurrency().replaceAll('\$ ',''), style: textStylePrice),
      textDirection: TextDirection.ltr,
    );
    pricePainter.layout();
    pricePainter.paint(canvas, Offset((width - pricePainter.width)/2, yPrice));

    // Imprimo el símbolo de la moneda
    final currencyPainter = TextPainter(
      text: const TextSpan(text: '\$', style: textStyleBig),
      textDirection: TextDirection.ltr,
    );
    currencyPainter.layout();
    currencyPainter.paint(canvas, Offset((width - pricePainter.width)/2 - 10 - currencyPainter.width, yPrice + 20));

    // 3. Código de barras
    if (product.barcodes != null && product.barcodes!.isNotEmpty) {
      final barcodeString = product.barcodes!.where((b)=>b.type == 1).first.barcode.toString();
      try {
        final bc = Barcode.code128();
        
        // Dibujar barras del código
        const bcWidth = 250.0;
        const bcHeight = 40.0;
        final bcX = 10;
        final bcY = yPrice + pricePainter.height + 10;
        
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
        print('Error al imprimir código de barras $e');
        // Ignorar errores de código de barras
      }
    }

    // 4. Info inferior (ID y Precio sin impuestos)
    final footerY = yPrice + pricePainter.height + 10;
    
    // final idPainter = TextPainter(
    //   text: TextSpan(text: "Cod: ${product.id}", style: textStyleSmall),
    //   textDirection: TextDirection.ltr,
    // );
    // idPainter.layout();
    // idPainter.paint(canvas, Offset(width - 10 - idPainter.width, footerY));

    double spaceBetweenSmallTexts = 2.5;

    // double yPriceWithoutTaxes = footerY + idPainter.height + spaceBetweenSmallTexts;
    double yPriceWithoutTaxes = footerY + spaceBetweenSmallTexts;
    final sinImpPainter = TextPainter(
      text: TextSpan(text: "Precio sin imp: ${basePrice.formatToCurrency()}", style: textStyleSmall),
      textDirection: TextDirection.ltr,
    );
    sinImpPainter.layout();
    sinImpPainter.paint(canvas, Offset(width - 10 - sinImpPainter.width, yPriceWithoutTaxes));

    // 5. Fecha
    final dateStr = _formatDate(DateTime.now());
    final datePainter = TextPainter(
      text: TextSpan(text: dateStr, style: textStyleSmall),
      textDirection: TextDirection.ltr,
    );
    datePainter.layout();
    datePainter.paint(canvas, Offset(width - 10 - datePainter.width, yPriceWithoutTaxes + sinImpPainter.height + spaceBetweenSmallTexts));

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    
    final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
    final buffer = pngBytes!.buffer.asUint8List();

    // Debug: Guardar imagen en el dispositivo para inspección
    if (kDebugMode) {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final filePath = p.join(
            directory.path, 'debug_label_${product.id}.png');
        final file = File(filePath);
        await file.writeAsBytes(buffer);
        debugPrint('DEBUG: Imagen de etiqueta guardada en: $filePath');
      } catch (e) {
        debugPrint('DEBUG: Error al guardar imagen de etiqueta: $e');
      }
    }

    return buffer;
  }

  static String _formatDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    return '$dd/$mm/$yyyy';
  }
}
