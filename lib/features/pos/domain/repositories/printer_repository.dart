import 'package:punto_venta_app/features/pos/domain/entities/printer_config.dart';
import 'package:punto_venta_app/features/pos/domain/entities/print_job.dart';
import 'package:punto_venta_app/features/pos/presentation/utils/templates/base_ticket_template.dart';

abstract class PrinterRepository {
  Future<bool> connect(PrinterConfig config);
  Future<bool> disconnect();
  Future<bool> printTicket(PrintJob printJob);
  Future<bool> printCommands(List<TicketCommand> commands);
  Future<bool> isConnected();

  /// `true` tras un [connect] exitoso por térmica integrada.
  bool get isUsingBuiltin;
}