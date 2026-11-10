import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:punto_venta_app/core/utils/app_logger.dart';
import 'package:punto_venta_app/features/pos/data/datasources/printer_builtin_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/printer_socket_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/printer_web_datasource.dart';
import 'package:punto_venta_app/features/pos/domain/entities/print_job.dart';
import 'package:punto_venta_app/features/pos/domain/entities/printer_config.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/printer_repository.dart';

class PrinterRepositoryImpl implements PrinterRepository {
  final PrinterSocketDatasource? printerDatasource;
  final PrinterWebDatasource? webDatasource;
  final PrinterBuiltinDatasource? builtinDatasource;

  bool _usingBuiltin = false;

  PrinterRepositoryImpl({
    this.printerDatasource,
    this.webDatasource,
    this.builtinDatasource,
  }) : assert(
          (kIsWeb && webDatasource != null) ||
              (!kIsWeb && printerDatasource != null),
          'Debe proporcionar el datasource correcto según la plataforma',
        );

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<bool> _shouldUseBuiltin(PrinterConfig config) async {
    if (!_isAndroid || builtinDatasource == null) return false;
    switch (config.outputMode) {
      case PrinterOutputMode.network:
        return false;
      case PrinterOutputMode.builtin:
        return await builtinDatasource!.isAvailable();
      case PrinterOutputMode.auto:
        return await builtinDatasource!.isAvailable();
    }
  }

  @override
  Future<bool> connect(PrinterConfig config) async {
    _usingBuiltin = await _shouldUseBuiltin(config);
    AppLogger.info(
      'PrinterRepository.connect mode=${config.outputMode.name} '
      'builtin=$_usingBuiltin ip=${config.ip}',
    );

    if (_usingBuiltin) {
      final ok = await builtinDatasource!.connect();
      if (ok) return true;
      // Fallback a IP si auto y hay IP configurada.
      if (config.outputMode == PrinterOutputMode.auto &&
          config.ip.trim().isNotEmpty &&
          printerDatasource != null) {
        AppLogger.info('PrinterRepository: builtin falló → fallback IP');
        _usingBuiltin = false;
        return printerDatasource!.connect(config);
      }
      return false;
    }

    return kIsWeb
        ? webDatasource!.connect(config)
        : printerDatasource!.connect(config);
  }

  @override
  Future<bool> disconnect() {
    if (_usingBuiltin && builtinDatasource != null) {
      _usingBuiltin = false;
      return builtinDatasource!.disconnect();
    }
    return kIsWeb
        ? webDatasource!.disconnect()
        : printerDatasource!.disconnect();
  }

  @override
  Future<bool> isConnected() {
    if (_usingBuiltin && builtinDatasource != null) {
      return builtinDatasource!.isConnected();
    }
    return kIsWeb
        ? webDatasource!.isConnected()
        : printerDatasource!.isConnected();
  }

  @override
  Future<bool> printTicket(PrintJob printJob) {
    if (_usingBuiltin && builtinDatasource != null) {
      return builtinDatasource!.printTicket(printJob);
    }
    return kIsWeb
        ? webDatasource!.printTicket(printJob)
        : printerDatasource!.printTicket(printJob);
  }
}
