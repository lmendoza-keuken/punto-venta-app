import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:punto_venta_app/app/routes/app_router.dart';
import 'package:punto_venta_app/core/utils/app_logger.dart';
import 'package:punto_venta_app/features/customer_display/domain/customer_display_snapshot.dart';
import 'package:punto_venta_app/features/customer_display/presentation/widgets/pta_lcd_view.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/product/product_image.dart';

/// Renderiza el widget [PtaLcdView] (320×240) y devuelve PNG.
Future<Uint8List> capturePtaLcdSnapshot(
  CustomerDisplaySnapshot snapshot, {
  int width = 320,
  int height = 240,
}) async {
  // Overlay.of(navigatorContext) FALLA: el Overlay es hijo del Navigator,
  // no ancestro. Hay que usar NavigatorState.overlay.
  final nav = AppRouter.navigatorKey.currentState;
  final overlay = nav?.overlay;
  if (overlay == null) {
    throw StateError('Sin Overlay del Navigator para capturar LCD');
  }

  await _precacheProductImage(overlay.context, snapshot);

  return _captureViaOverlay(
    overlay,
    snapshot,
    width: width,
    height: height,
  );
}

Future<Uint8List> _captureViaOverlay(
  OverlayState overlay,
  CustomerDisplaySnapshot snapshot, {
  required int width,
  required int height,
}) async {
  final boundaryKey = GlobalKey();
  late OverlayEntry entry;

  // Widget real 320×240. Opacity AFUERA del boundary (toImage = alpha pleno).
  entry = OverlayEntry(
    maintainState: true,
    builder: (_) => Positioned(
      left: 0,
      top: 0,
      width: width.toDouble(),
      height: height.toDouble(),
      child: Opacity(
        opacity: 0.02,
        child: IgnorePointer(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: MediaQuery(
              data: MediaQueryData(
                size: Size(width.toDouble(), height.toDouble()),
              ),
              child: Theme(
                data: ThemeData.light(useMaterial3: false),
                child: RepaintBoundary(
                  key: boundaryKey,
                  child: PtaLcdView(
                    snapshot: snapshot,
                    width: width.toDouble(),
                    height: height.toDouble(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  overlay.insert(entry);
  try {
    await WidgetsBinding.instance.endOfFrame;
    final hasImage =
        (snapshot.lastProduct?.imageUrl?.trim().isNotEmpty ?? false) ||
            (snapshot.adProducts.isNotEmpty &&
                (snapshot.adProducts.first.imageUrl?.trim().isNotEmpty ??
                    false));
    await Future<void>.delayed(
      Duration(milliseconds: hasImage ? 180 : 50),
    );
    await WidgetsBinding.instance.endOfFrame;

    final boundary = boundaryKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null || !boundary.hasSize) {
      throw StateError('RepaintBoundary no listo');
    }
    if (boundary.size.width < width * 0.9 ||
        boundary.size.height < height * 0.9) {
      throw StateError(
        'RepaintBoundary size inválido ${boundary.size} '
        '(esperado ${width}x$height)',
      );
    }
    if (boundary.debugNeedsPaint) {
      await WidgetsBinding.instance.endOfFrame;
    }

    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw StateError('toByteData PNG falló');
      }
      final bytes = byteData.buffer.asUint8List();
      if (bytes.length < 200) {
        throw StateError('PNG sospechosamente chico (${bytes.length} bytes)');
      }
      AppLogger.info(
        'PtaLcdCapture widget ok ${image.width}x${image.height} '
        'bytes=${bytes.length} mode=${snapshot.mode.name}',
      );
      return bytes;
    } finally {
      image.dispose();
    }
  } finally {
    entry.remove();
  }
}

Future<void> _precacheProductImage(
  BuildContext context,
  CustomerDisplaySnapshot snapshot,
) async {
  final url = snapshot.lastProduct?.imageUrl?.trim() ??
      (snapshot.adProducts.isNotEmpty
          ? snapshot.adProducts.first.imageUrl?.trim()
          : null);
  if (url == null || url.isEmpty) return;

  try {
    final ImageProvider provider;
    if (ProductImage.isAssetUrl(url)) {
      provider = AssetImage(ProductImage.assetPathFromUrl(url));
    } else if (url.startsWith('assets/')) {
      provider = AssetImage(url);
    } else {
      provider = NetworkImage(url);
    }
    await precacheImage(provider, context).timeout(
      const Duration(seconds: 2),
      onTimeout: () {},
    );
  } catch (e) {
    AppLogger.warn('PtaLcdCapture: precache falló ($e)');
  }
}
