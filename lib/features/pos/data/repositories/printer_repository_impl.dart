import 'package:pos_flutter_app/features/pos/data/datasources/printer_socket_datasource.dart';
import 'package:pos_flutter_app/features/pos/domain/entities/print_job.dart';
import 'package:pos_flutter_app/features/pos/domain/entities/printer_config.dart';
import 'package:pos_flutter_app/features/pos/domain/repositories/printer_repository.dart';

class PrinterRepositoryImpl implements PrinterRepository {
  final PrinterSocketDatasource printerDatasource;

  PrinterRepositoryImpl({required this.printerDatasource});

  @override
  Future<bool> connect(PrinterConfig config) {
    return printerDatasource.connect(config);
  }

  @override
  Future<bool> disconnect() {
    return printerDatasource.disconnect();
  }

  @override
  Future<bool> isConnected() {
    return printerDatasource.isConnected();
  }

  @override
  Future<bool> printTicket(PrintJob printJob) {
    return printerDatasource.printTicket(printJob);
  }
}