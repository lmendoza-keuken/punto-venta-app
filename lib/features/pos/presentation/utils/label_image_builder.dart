import 'dart:io';
import 'dart:ui' as ui;

import 'package:barcode/barcode.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:punto_venta_app/core/utils/extensions.dart';
import 'package:punto_venta_app/features/pos/domain/entities/product.dart';

/// Etiquetas de góndola.
///
/// - IP / red: layout histórico 576×314.
/// - PTA integrada: layout ajustado a 384 dots (58mm) sin achicar un PNG grande.
class LabelImageBuilder {
  static const int designWidth = 576;
  static const int designHeight = 314;

  /// Ancho máx. PTA 58mm ([ThermalPrinterChannel.MAX_DOTS_PER_LINE]).
  static const int ptaWidth = 384;
  static const int ptaHeight = 240;

  static Future<Uint8List> buildProductLabelImage(
    Product product, {
    /// Solo para térmica integrada PTA0130.
    bool forPta = false,
  }) async {
    if (forPta) {
      return _buildPtaLabel(product);
    }
    return _buildNetworkLabel(product);
  }

  /// Layout original (impresora IP / ESC-POS).
  static Future<Uint8List> _buildNetworkLabel(Product product) async {
    const double width = 576;
    const double height = 314;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

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

    final name = product.name.toUpperCase();
    final textPainter = TextPainter(
      text: TextSpan(text: name, style: textStyleBig),
      textDirection: ui.TextDirection.ltr,
      maxLines: 2,
      ellipsis: '...',
    );
    textPainter.layout(maxWidth: width - 20);
    textPainter.paint(canvas, const Offset(10, 5));

    final yPrice = textPainter.height + 10;
    final basePrice = product.price ?? 0.0;
    final vatPercent = product.vat;
    final priceWithVat = basePrice + (basePrice * (vatPercent / 100));

    final pricePainter = TextPainter(
      text: TextSpan(
        text: priceWithVat.formatToCurrency().replaceAll('\$ ', ''),
        style: textStylePrice,
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    pricePainter.paint(
      canvas,
      Offset((width - pricePainter.width) / 2, yPrice),
    );

    final currencyPainter = TextPainter(
      text: const TextSpan(text: '\$', style: textStyleBig),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    currencyPainter.paint(
      canvas,
      Offset(
        (width - pricePainter.width) / 2 - 10 - currencyPainter.width,
        yPrice + 20,
      ),
    );

    if (product.barcodes != null && product.barcodes!.isNotEmpty) {
      final type1 = product.barcodes!.where((b) => b.type == 1);
      if (type1.isNotEmpty) {
        final barcodeString = type1.first.barcode.toString();
        try {
          final bc = Barcode.code128();
          const bcWidth = 250.0;
          const bcHeight = 40.0;
          const bcX = 10.0;
          final bcY = yPrice + pricePainter.height + 10;

          for (final element
              in bc.make(barcodeString, width: bcWidth, height: bcHeight)) {
            if (element is BarcodeBar && element.black) {
              canvas.drawRect(
                Rect.fromLTWH(
                  bcX + element.left,
                  bcY + element.top,
                  element.width,
                  element.height,
                ),
                Paint()..color = Colors.black,
              );
            }
          }

          final bcTextPainter = TextPainter(
            text: TextSpan(
              text: barcodeString,
              style: textStyleSmall.copyWith(fontSize: 16),
            ),
            textDirection: ui.TextDirection.ltr,
          )..layout();
          bcTextPainter.paint(
            canvas,
            Offset(
              bcX + (bcWidth - bcTextPainter.width) / 2,
              bcY + bcHeight + 2,
            ),
          );
        } catch (e) {
          debugPrint('Error barcode etiqueta IP: $e');
        }
      }
    }

    final footerY = yPrice + pricePainter.height + 10;
    const spaceBetweenSmallTexts = 2.5;
    final yPriceWithoutTaxes = footerY + spaceBetweenSmallTexts;
    final sinImpPainter = TextPainter(
      text: TextSpan(
        text: 'Precio sin imp: ${basePrice.formatToCurrency()}',
        style: textStyleSmall,
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    sinImpPainter.paint(
      canvas,
      Offset(width - 10 - sinImpPainter.width, yPriceWithoutTaxes),
    );

    final datePainter = TextPainter(
      text: TextSpan(text: _formatDate(DateTime.now()), style: textStyleSmall),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    datePainter.paint(
      canvas,
      Offset(
        width - 10 - datePainter.width,
        yPriceWithoutTaxes + sinImpPainter.height + spaceBetweenSmallTexts,
      ),
    );

    return _encodePng(
      recorder,
      width.toInt(),
      height.toInt(),
      productId: product.id,
    );
  }

  /// Layout PTA 58mm: precio alto, barcode/footer legibles, sin estirar papel.
  static Future<Uint8List> _buildPtaLabel(Product product) async {
    final double w = ptaWidth.toDouble();
    final double h = ptaHeight.toDouble();

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = Colors.white,
    );

    const pad = 8.0;
    const nameSize = 28.0;
    const priceIntegerSize = 88.0;
    const priceCentsSize = 34.0;
    const dollarSize = 30.0;
    const footerSize = 13.0;
    const barcodeDigitsSize = 12.0;

    final namePainter = TextPainter(
      text: TextSpan(
        text: product.name.toUpperCase(),
        style: const TextStyle(
          color: Colors.black,
          fontSize: nameSize,
          fontWeight: ui.FontWeight.bold,
          height: 1.05,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
      maxLines: 2,
      ellipsis: '...',
    );
    namePainter.layout(maxWidth: w - pad * 2);
    namePainter.paint(canvas, const Offset(pad, 4));

    final basePrice = product.price ?? 0.0;
    final vatPercent = product.vat;
    final priceWithVat = basePrice + (basePrice * (vatPercent / 100));
    final priceFmt = NumberFormat('#,##0.00', 'es_AR');
    final priceParts = priceFmt.format(priceWithVat).split(',');
    final integerPart = priceParts.first;
    final centsPart = priceParts.length > 1 ? priceParts[1] : '00';

    final dollarPainter = TextPainter(
      text: const TextSpan(
        text: '\$',
        style: TextStyle(
          color: Colors.black,
          fontSize: dollarSize,
          fontWeight: ui.FontWeight.bold,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    final integerPainter = TextPainter(
      text: TextSpan(
        text: integerPart,
        style: const TextStyle(
          color: Colors.black,
          fontSize: priceIntegerSize,
          fontWeight: ui.FontWeight.bold,
          height: 1,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    final centsPainter = TextPainter(
      text: TextSpan(
        text: centsPart,
        style: const TextStyle(
          color: Colors.black,
          fontSize: priceCentsSize,
          fontWeight: ui.FontWeight.bold,
          height: 1,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    const priceGap = 3.0;
    final priceBlockW = dollarPainter.width +
        priceGap +
        integerPainter.width +
        priceGap * 0.5 +
        centsPainter.width;
    final priceTop = namePainter.height + 4;
    final priceLeft = ((w - priceBlockW) / 2).clamp(pad, w - pad);

    dollarPainter.paint(
      canvas,
      Offset(priceLeft, priceTop + integerPainter.height * 0.32),
    );
    integerPainter.paint(
      canvas,
      Offset(priceLeft + dollarPainter.width + priceGap, priceTop),
    );
    centsPainter.paint(
      canvas,
      Offset(
        priceLeft + dollarPainter.width + priceGap + integerPainter.width + 2,
        priceTop + 4,
      ),
    );

    final priceBottom = priceTop + integerPainter.height;
    final bottomTop = priceBottom + 4;
    final barcodeColW = w * 0.55;
    final bottomHeight = h - bottomTop - pad;
    final bcHeight = (bottomHeight * 0.42).clamp(30.0, 44.0);
    final bcWidth = barcodeColW - pad;

    if (product.barcodes != null && product.barcodes!.isNotEmpty) {
      final type1 = product.barcodes!.where((b) => b.type == 1);
      if (type1.isNotEmpty) {
        final barcodeString = type1.first.barcode.toString();
        try {
          final bc = Barcode.code128();
          for (final element in bc.make(
            barcodeString,
            width: bcWidth,
            height: bcHeight,
          )) {
            if (element is BarcodeBar && element.black) {
              canvas.drawRect(
                Rect.fromLTWH(
                  pad + element.left,
                  bottomTop + element.top,
                  element.width,
                  element.height,
                ),
                Paint()..color = Colors.black,
              );
            }
          }

          final digitsPainter = TextPainter(
            text: TextSpan(
              text: barcodeString,
              style: const TextStyle(
                color: Colors.black,
                fontSize: barcodeDigitsSize,
                fontWeight: ui.FontWeight.w500,
              ),
            ),
            textDirection: ui.TextDirection.ltr,
          )..layout();
          digitsPainter.paint(
            canvas,
            Offset(
              pad + (bcWidth - digitsPainter.width) / 2,
              bottomTop + bcHeight + 2,
            ),
          );
        } catch (e) {
          debugPrint('Error barcode etiqueta PTA: $e');
        }
      }
    }

    final rightLeft = pad + barcodeColW + 4;
    final rightMaxW = w - rightLeft - pad;
    const footerStyle = TextStyle(
      color: Colors.black,
      fontSize: footerSize,
      fontWeight: ui.FontWeight.w600,
      height: 1.15,
    );

    final sinImpLabel = TextPainter(
      text: const TextSpan(text: 'Precio sin impuestos:', style: footerStyle),
      textDirection: ui.TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
    )..layout(maxWidth: rightMaxW);
    sinImpLabel.paint(canvas, Offset(rightLeft, bottomTop));

    final sinImpValue = TextPainter(
      text: TextSpan(
        text: basePrice.formatToCurrency(),
        style: footerStyle,
      ),
      textDirection: ui.TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: rightMaxW);
    sinImpValue.paint(
      canvas,
      Offset(rightLeft, bottomTop + sinImpLabel.height + 1),
    );

    return _encodePng(
      recorder,
      w.toInt(),
      h.toInt(),
      productId: product.id,
    );
  }

  static Future<Uint8List> _encodePng(
    ui.PictureRecorder recorder,
    int width,
    int height, {
    required int productId,
  }) async {
    final picture = recorder.endRecording();
    final img = await picture.toImage(width, height);
    final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
    final buffer = pngBytes!.buffer.asUint8List();

    if (kDebugMode) {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final filePath = p.join(
          directory.path,
          'debug_label_${productId}_${width}.png',
        );
        await File(filePath).writeAsBytes(buffer);
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
