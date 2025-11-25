import 'package:punto_venta_app/features/pos/domain/entities/printer_config.dart';
import 'package:punto_venta_app/features/pos/domain/entities/print_job.dart';

abstract class PrinterRepository {
  Future<bool> connect(PrinterConfig config);
  Future<bool> disconnect();
  Future<bool> printTicket(PrintJob printJob);
  Future<bool> isConnected();
}