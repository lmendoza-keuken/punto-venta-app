import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:punto_venta_app/core/utils/app_logger.dart';
import 'package:punto_venta_app/features/customer_display/data/pta_lcd_capture.dart';
import 'package:punto_venta_app/features/customer_display/domain/customer_display_snapshot.dart';

/// Cliente Dart del LCD SPI del PTA0130 (Binder `SubScreen`, 320×240).
///
/// No es un Display Android: no sirve `presentation_displays` en este hardware.
class PtaSubScreen {
  PtaSubScreen._();

  static const _channel = MethodChannel(
    'ar.com.keuken.punto_venta_app/subscreen',
  );

  /// Generación: descarta capturas viejas que terminan tarde (scans rápidos).
  static int _snapshotGen = 0;
  static CustomerDisplaySnapshot? _queuedSnapshot;
  static Future<void> _snapshotGate = Future<void>.value();

  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// `true` si el framework expone el servicio `SubScreen`.
  static Future<bool> isAvailable() async {
    if (!_isAndroid) return false;
    try {
      final v = await _channel.invokeMethod<bool>('isAvailable');
      return v == true;
    } catch (e, st) {
      AppLogger.error('PtaSubScreen.isAvailable', e, st);
      return false;
    }
  }

  /// Info del LCD. `available` exige device `/dev/tp_spi_lcd`.
  static Future<PtaSubScreenInfo> getInfo() async {
    if (!_isAndroid) return const PtaSubScreenInfo.unavailable();
    try {
      final map = await _channel.invokeMapMethod<String, dynamic>('getInfo');
      if (map == null) return const PtaSubScreenInfo.unavailable();
      return PtaSubScreenInfo.fromMap(map);
    } catch (e, st) {
      AppLogger.error('PtaSubScreen.getInfo', e, st);
      return const PtaSubScreenInfo.unavailable();
    }
  }

  /// Enciende e inicializa el LCD. Idempotente (código 61444 = ya init).
  static Future<PtaSubScreenResult> init() async {
    if (!_isAndroid) {
      return const PtaSubScreenResult(ok: false, code: -1);
    }
    try {
      final map = await _channel.invokeMapMethod<String, dynamic>('init');
      final result = PtaSubScreenResult.fromMap(map);
      AppLogger.info('PtaSubScreen.init code=${result.code} ok=${result.ok}');
      return result;
    } catch (e, st) {
      AppLogger.error('PtaSubScreen.init', e, st);
      return PtaSubScreenResult(ok: false, code: -1, error: '$e');
    }
  }

  static Future<PtaSubScreenResult> release() async {
    if (!_isAndroid) {
      return const PtaSubScreenResult(ok: false, code: -1);
    }
    try {
      final map = await _channel.invokeMapMethod<String, dynamic>('release');
      final result = PtaSubScreenResult.fromMap(map);
      AppLogger.info('PtaSubScreen.release code=${result.code} ok=${result.ok}');
      return result;
    } catch (e, st) {
      AppLogger.error('PtaSubScreen.release', e, st);
      return PtaSubScreenResult(ok: false, code: -1, error: '$e');
    }
  }

  /// Cierre controlado: negro + settle SPI + release (nativo síncrono).
  /// Await esto **antes** de [SystemNavigator.pop] / matar el proceso.
  static Future<PtaSubScreenResult> shutdown() async {
    if (!_isAndroid) {
      return const PtaSubScreenResult(ok: false, code: -1);
    }
    try {
      final map = await _channel.invokeMapMethod<String, dynamic>('shutdown');
      final result = PtaSubScreenResult.fromMap(map);
      AppLogger.info(
        'PtaSubScreen.shutdown code=${result.code} ok=${result.ok}',
      );
      return result;
    } catch (e, st) {
      AppLogger.error('PtaSubScreen.shutdown', e, st);
      return PtaSubScreenResult(ok: false, code: -1, error: '$e');
    }
  }

  /// Prueba de hardware: color sólido + texto opcional (auto-init).
  static Future<PtaSubScreenResult> showColor(
    int argb, {
    String? label,
  }) async {
    if (!_isAndroid) {
      return const PtaSubScreenResult(ok: false, code: -1);
    }
    try {
      final map = await _channel.invokeMapMethod<String, dynamic>(
        'showColor',
        {'color': argb, 'label': label},
      );
      final result = PtaSubScreenResult.fromMap(map);
      AppLogger.info(
        'PtaSubScreen.showColor code=${result.code} ok=${result.ok}',
      );
      return result;
    } catch (e, st) {
      AppLogger.error('PtaSubScreen.showColor', e, st);
      return PtaSubScreenResult(ok: false, code: -1, error: '$e');
    }
  }

  /// Muestra un PNG/JPEG; se escala a 320×240 en nativo.
  ///
  /// No llama [init] desde Dart: el canal nativo hace `ensureReady` solo si
  /// hace falta. Un `init` extra pinta el azul por defecto encima del frame.
  static Future<PtaSubScreenResult> showBitmap(
    Uint8List bytes, {
    int x = 0,
    int y = 0,
  }) async {
    if (!_isAndroid) {
      return const PtaSubScreenResult(ok: false, code: -1);
    }
    try {
      // Sin timeout corto: abortar a los 8s mientras init nativo sigue
      // bloqueado deja el SPI en ERR_BUSY (61448) y el LCD en nieve.
      final map = await _channel.invokeMapMethod<String, dynamic>(
        'showBitmap',
        {'bytes': bytes, 'x': x, 'y': y},
      );
      final result = PtaSubScreenResult.fromMap(map);
      AppLogger.info(
        'PtaSubScreen.showBitmap code=${result.code} ok=${result.ok} '
        'bytes=${bytes.length}',
      );
      return result;
    } catch (e, st) {
      AppLogger.error('PtaSubScreen.showBitmap', e, st);
      return PtaSubScreenResult(ok: false, code: -1, error: '$e');
    }
  }

  /// Prueba: asset del bundle → LCD (JPEG/PNG).
  static Future<PtaSubScreenResult> showImageAsset(
    String assetPath,
  ) async {
    if (!_isAndroid) {
      return const PtaSubScreenResult(ok: false, code: -1);
    }
    try {
      AppLogger.info('PtaSubScreen.showImageAsset path=$assetPath');
      final data = await rootBundle.load(assetPath);
      return await showBitmap(data.buffer.asUint8List());
    } catch (e, st) {
      AppLogger.error('PtaSubScreen.showImageAsset', e, st);
      return PtaSubScreenResult(ok: false, code: -1, error: '$e');
    }
  }

  /// Prueba: descarga URL (http/https) → LCD.
  static Future<PtaSubScreenResult> showImageUrl(String url) async {
    if (!_isAndroid) {
      return const PtaSubScreenResult(ok: false, code: -1);
    }
    try {
      AppLogger.info('PtaSubScreen.showImageUrl url=$url');
      final uri = Uri.parse(url);
      final client = HttpClient();
      try {
        final request = await client.getUrl(uri);
        final response = await request.close();
        if (response.statusCode < 200 || response.statusCode >= 300) {
          return PtaSubScreenResult(
            ok: false,
            code: response.statusCode,
            error: 'http_${response.statusCode}',
          );
        }
        final bytes = await consolidateHttpClientResponseBytes(response);
        return await showBitmap(bytes);
      } finally {
        client.close(force: true);
      }
    } catch (e, st) {
      AppLogger.error('PtaSubScreen.showImageUrl', e, st);
      return PtaSubScreenResult(ok: false, code: -1, error: '$e');
    }
  }

  /// Asset de prueba embebido en el proyecto.
  static const testImageAsset =
      'assets/mock/product_3_secco_naranja.jpg';

  static Future<PtaSubScreenResult> showTestImage() =>
      showImageAsset(testImageAsset);

  /// Captura el widget [PtaLcdView] (320×240) y lo manda al LCD.
  ///
  /// Solo el snapshot más reciente gana: si llega otro sync mientras se
  /// captura, el bitmap viejo se descarta (evita LCD “pegado” al carrito anterior).
  /// No re-inicializa el SPI: eso flashaba blanco/nieve entre frames.
  /// Para cambiar el diseño: editá `presentation/widgets/pta_lcd_view.dart`.
  static Future<PtaSubScreenResult> showSnapshot(
    CustomerDisplaySnapshot snapshot,
  ) {
    if (!_isAndroid) {
      return Future.value(const PtaSubScreenResult(ok: false, code: -1));
    }

    final gen = ++_snapshotGen;
    _queuedSnapshot = snapshot;
    final done = Completer<PtaSubScreenResult>();

    _snapshotGate = _snapshotGate.catchError((_) {}).then((_) async {
      if (gen != _snapshotGen) {
        done.complete(
          const PtaSubScreenResult(ok: true, code: 0, error: 'superseded'),
        );
        return;
      }
      final snap = _queuedSnapshot ?? snapshot;
      try {
        final info = await getInfo();
        if (gen != _snapshotGen) {
          done.complete(
            const PtaSubScreenResult(ok: true, code: 0, error: 'superseded'),
          );
          return;
        }
        if (!info.available) {
          done.complete(
            const PtaSubScreenResult(
              ok: false,
              code: 61442,
              error: 'no_device',
            ),
          );
          return;
        }
        // Warm init en paralelo con la captura: el SPI del PTA tarda ~5s en
        // el primer init; si esperamos a showBitmap, se suma al capture.
        final warmInit = init();

        // Camino principal: widget PtaLcdView → PNG → LCD.
        Uint8List? png;
        try {
          png = await capturePtaLcdSnapshot(
            snap,
            width: info.width ?? 320,
            height: info.height ?? 240,
          );
        } catch (e, st) {
          AppLogger.error(
            'PtaSubScreen.showSnapshot: captura widget falló → fallback color',
            e,
            st,
          );
        }

        final warm = await warmInit;
        AppLogger.info(
          'PtaSubScreen.showSnapshot: warm init '
          'ok=${warm.ok} code=${warm.code}',
        );

        if (gen != _snapshotGen) {
          AppLogger.info(
            'PtaSubScreen.showSnapshot: descarta frame viejo '
            'mode=${snap.mode.name} gen=$gen current=$_snapshotGen',
          );
          done.complete(
            const PtaSubScreenResult(ok: true, code: 0, error: 'superseded'),
          );
          return;
        }

        if (png == null) {
          final fallback = await showColor(
            _fallbackColor(snap),
            label: _fallbackLabel(snap),
          );
          done.complete(fallback);
          return;
        }

        final shown = await showBitmap(png);
        AppLogger.info(
          'PtaSubScreen.showSnapshot: widget→bitmap '
          'mode=${snap.mode.name} ok=${shown.ok} code=${shown.code}',
        );
        done.complete(shown);
      } catch (e, st) {
        AppLogger.error('PtaSubScreen.showSnapshot', e, st);
        if (!done.isCompleted) {
          try {
            final fallback = await showColor(
              _fallbackColor(snapshot),
              label: _fallbackLabel(snapshot),
            );
            done.complete(fallback);
          } catch (_) {
            done.complete(PtaSubScreenResult(ok: false, code: -1, error: '$e'));
          }
        }
      }
    });

    return done.future;
  }

  static int _fallbackColor(CustomerDisplaySnapshot snap) => switch (snap.mode) {
        CustomerDisplayMode.payment => 0xFF1B5E20,
        CustomerDisplayMode.done => 0xFF0D47A1,
        CustomerDisplayMode.cart => 0xFF111111,
        CustomerDisplayMode.advertising => 0xFF0B6E4F,
        // No usar el azul del init nativo: si falló la captura, igual se nota el texto.
        CustomerDisplayMode.idle => 0xFF102A43,
      };

  static String _fallbackLabel(CustomerDisplaySnapshot snap) {
    switch (snap.mode) {
      case CustomerDisplayMode.idle:
      case CustomerDisplayMode.advertising:
        return 'KEUKEN';
      case CustomerDisplayMode.cart:
        final name = snap.lastProduct?.name;
        final total = snap.totalConIva.toStringAsFixed(2);
        if (name != null && name.isNotEmpty) {
          final short = name.length > 14 ? '${name.substring(0, 14)}…' : name;
          return 'TOTAL \$$total\n$short';
        }
        return 'TOTAL\n\$$total';
      case CustomerDisplayMode.payment:
        return 'PAGAR\n\$${snap.totalConIva.toStringAsFixed(2)}';
      case CustomerDisplayMode.done:
        return 'GRACIAS';
    }
  }
}

class PtaSubScreenInfo {
  const PtaSubScreenInfo({
    required this.available,
    this.width,
    this.height,
    this.version,
    this.rawWidth,
    this.rawHeight,
  });

  const PtaSubScreenInfo.unavailable()
      : available = false,
        width = null,
        height = null,
        version = null,
        rawWidth = null,
        rawHeight = null;

  factory PtaSubScreenInfo.fromMap(Map<String, dynamic> map) {
    return PtaSubScreenInfo(
      available: map['available'] == true,
      width: (map['width'] as num?)?.toInt(),
      height: (map['height'] as num?)?.toInt(),
      version: map['version'] as String?,
      rawWidth: (map['rawWidth'] as num?)?.toInt(),
      rawHeight: (map['rawHeight'] as num?)?.toInt(),
    );
  }

  final bool available;
  final int? width;
  final int? height;
  final String? version;
  final int? rawWidth;
  final int? rawHeight;
}

class PtaSubScreenResult {
  const PtaSubScreenResult({
    required this.ok,
    required this.code,
    this.error,
  });

  factory PtaSubScreenResult.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const PtaSubScreenResult(ok: false, code: -1);
    }
    return PtaSubScreenResult(
      ok: map['ok'] == true,
      code: (map['code'] as num?)?.toInt() ?? -1,
      error: map['error'] as String?,
    );
  }

  final bool ok;
  final int code;
  final String? error;
}
