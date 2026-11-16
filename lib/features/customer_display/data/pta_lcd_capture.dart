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

/// La captura quedó obsoleta (llegó un snapshot más nuevo).
class PtaLcdCaptureAborted implements Exception {
  const PtaLcdCaptureAborted();
}

String? _lastPrecachedUrl;
DateTime? _lastPrecachedAt;

/// Renderiza el widget [PtaLcdView] (320×240) y devuelve PNG.
Future<Uint8List> capturePtaLcdSnapshot(
  CustomerDisplaySnapshot snapshot, {
  int width = 320,
  int height = 240,
  bool Function()? shouldAbort,
}) async {
  void checkAbort() {
    if (shouldAbort?.call() == true) {
      throw const PtaLcdCaptureAborted();
    }
  }

  final nav = AppRouter.navigatorKey.currentState;
  final overlay = nav?.overlay;
  if (overlay == null) {
    throw StateError('Sin Overlay del Navigator para capturar LCD');
  }

  checkAbort();
  await _precacheProductImage(overlay.context, snapshot);
  checkAbort();

  return _captureViaOverlay(
    overlay,
    snapshot,
    width: width,
    height: height,
    shouldAbort: shouldAbort,
  );
}

Future<Uint8List> _captureViaOverlay(
  OverlayState overlay,
  CustomerDisplaySnapshot snapshot, {
  required int width,
  required int height,
  bool Function()? shouldAbort,
}) async {
  void checkAbort() {
    if (shouldAbort?.call() == true) {
      throw const PtaLcdCaptureAborted();
    }
  }

  final boundaryKey = GlobalKey();
  late OverlayEntry entry;

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
    checkAbort();

    final url = snapshot.lastProduct?.imageUrl?.trim() ??
        (snapshot.adProducts.isNotEmpty
            ? snapshot.adProducts.first.imageUrl?.trim()
            : null);
    final hasImage = url != null && url.isNotEmpty;
    final recentlyCached = hasImage &&
        url == _lastPrecachedUrl &&
        _lastPrecachedAt != null &&
        DateTime.now().difference(_lastPrecachedAt!) <
            const Duration(seconds: 12);

    // Misma imagen en burst: no esperar 180ms otra vez.
    final settleMs = !hasImage
        ? 40
        : (recentlyCached ? 70 : 140);
    await Future<void>.delayed(Duration(milliseconds: settleMs));
    checkAbort();
    await WidgetsBinding.instance.endOfFrame;
    checkAbort();

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
      checkAbort();
    }

    final image = await boundary.toImage(pixelRatio: 1);
    try {
      checkAbort();
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

  if (url == _lastPrecachedUrl &&
      _lastPrecachedAt != null &&
      DateTime.now().difference(_lastPrecachedAt!) <
          const Duration(seconds: 12)) {
    return;
  }

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
    _lastPrecachedUrl = url;
    _lastPrecachedAt = DateTime.now();
  } catch (e) {
    AppLogger.warn('PtaLcdCapture: precache falló ($e)');
  }
}
