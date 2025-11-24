import 'package:pos_flutter_app/features/pos/domain/entities/print_job.dart';
import 'package:pos_flutter_app/features/pos/domain/entities/printer_config.dart';

abstract class PrinterEvent {
  const PrinterEvent();
}

class ConnectPrinter extends PrinterEvent {
  final PrinterConfig config;
  
  const ConnectPrinter(this.config);
}

class DisconnectPrinter extends PrinterEvent {}

class PrintTicket extends PrinterEvent {
  final PrintJob printJob;
  final PrinterConfig config;
  
  const PrintTicket({
    required this.printJob,
    required this.config,
  });
}

class CheckPrinterStatus extends PrinterEvent {}