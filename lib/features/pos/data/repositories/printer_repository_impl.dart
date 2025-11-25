import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:punto_venta_app/features/pos/data/datasources/printer_socket_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/printer_web_datasource.dart';
import 'package:punto_venta_app/features/pos/domain/entities/print_job.dart';
import 'package:punto_venta_app/features/pos/domain/entities/printer_config.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/printer_repository.dart';

class PrinterRepositoryImpl implements PrinterRepository {
  final PrinterSocketDatasource? printerDatasource;
  final PrinterWebDatasource? webDatasource;

  PrinterRepositoryImpl({
    this.printerDatasource,
    this.webDatasource,
  }) : assert(
          (kIsWeb && webDatasource != null) ||
              (!kIsWeb && printerDatasource != null),
          'Debe proporcionar el datasource correcto según la plataforma',
        );

  @override
  Future<bool> connect(PrinterConfig config) {
    return kIsWeb
        ? webDatasource!.connect(config)
        : printerDatasource!.connect(config);
  }

  @override
  Future<bool> disconnect() {
    return kIsWeb
        ? webDatasource!.disconnect()
        : printerDatasource!.disconnect();
  }

  @override
  Future<bool> isConnected() {
    return kIsWeb
        ? webDatasource!.isConnected()
        : printerDatasource!.isConnected();
  }

  @override
  Future<bool> printTicket(PrintJob printJob) {
    return kIsWeb
        ? webDatasource!.printTicket(printJob)
        : printerDatasource!.printTicket(printJob);
  }
}