import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:punto_venta_app/core/utils/app_logger.dart';

/// Cliente Dart de la impresora térmica integrada (PTA0130 / Telpo).
class PtaThermalPrinter {
  PtaThermalPrinter._();

  static const _channel = MethodChannel(
    'ar.com.keuken.punto_venta_app/thermal_printer',
  );

  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<bool> isAvailable() async {
    if (!_isAndroid) return false;
    try {
      final v = await _channel.invokeMethod<bool>('isAvailable');
      return v == true;
    } catch (e, st) {
      AppLogger.error('PtaThermalPrinter.isAvailable', e, st);
      return false;
    }
  }

  static Future<PtaThermalPrinterInfo> getInfo() async {
    if (!_isAndroid) return const PtaThermalPrinterInfo.unavailable();
    try {
      final map = await _channel.invokeMapMethod<String, dynamic>('getInfo');
      if (map == null) return const PtaThermalPrinterInfo.unavailable();
      return PtaThermalPrinterInfo.fromMap(map);
    } catch (e, st) {
      AppLogger.error('PtaThermalPrinter.getInfo', e, st);
      return const PtaThermalPrinterInfo.unavailable();
    }
  }

  static Future<bool> connect() async {
    if (!_isAndroid) return false;
    try {
      final map = await _channel.invokeMapMethod<String, dynamic>('connect');
      final ok = map?['ok'] == true;
      AppLogger.info(
        'PtaThermalPrinter.connect ok=$ok class=${map?['className']}',
      );
      return ok;
    } catch (e, st) {
      AppLogger.error('PtaThermalPrinter.connect', e, st);
      return false;
    }
  }

  static Future<bool> disconnect() async {
    if (!_isAndroid) return false;
    try {
      final map = await _channel.invokeMapMethod<String, dynamic>('disconnect');
      return map?['ok'] == true;
    } catch (e, st) {
      AppLogger.error('PtaThermalPrinter.disconnect', e, st);
      return false;
    }
  }

  /// Ejecuta comandos ya serializados (ver [PrinterBuiltinDatasource]).
  static Future<bool> printCommands(List<Map<String, dynamic>> commands) async {
    if (!_isAndroid) return false;
    try {
      final map = await _channel.invokeMapMethod<String, dynamic>(
        'printCommands',
        {'commands': commands},
      );
      final ok = map?['ok'] == true;
      AppLogger.info(
        'PtaThermalPrinter.printCommands ok=$ok count=${commands.length} cut=${map?['cut']} status=${map?['status']}',
      );
      return ok;
    } on PlatformException catch (e, st) {
      AppLogger.error(
        'PtaThermalPrinter.printCommands code=${e.code} ${e.message}',
        e,
        st,
      );
      rethrow;
    } catch (e, st) {
      AppLogger.error('PtaThermalPrinter.printCommands', e, st);
      return false;
    }
  }
}

class PtaThermalPrinterInfo {
  const PtaThermalPrinterInfo({
    required this.available,
    this.className,
    this.version,
    this.backend,
    this.detail,
  });

  const PtaThermalPrinterInfo.unavailable()
      : available = false,
        className = null,
        version = null,
        backend = null,
        detail = null;

  factory PtaThermalPrinterInfo.fromMap(Map<String, dynamic> map) {
    return PtaThermalPrinterInfo(
      available: map['available'] == true,
      className: map['className'] as String?,
      version: map['version'] as String?,
      backend: map['backend'] as String?,
      detail: map['detail'] as String?,
    );
  }

  final bool available;
  final String? className;
  final String? version;
  final String? backend;
  final String? detail;
}
