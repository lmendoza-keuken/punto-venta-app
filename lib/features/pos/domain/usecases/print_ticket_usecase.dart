import 'package:flutter/services.dart';
import 'package:punto_venta_app/features/pos/domain/entities/print_job.dart';
import 'package:punto_venta_app/features/pos/domain/entities/printer_config.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/printer_repository.dart';

class PrintTicketUsecase {
  final PrinterRepository printerRepository;

  PrintTicketUsecase(this.printerRepository);

  Future<bool> call({
    required PrintJob printJob,
    required PrinterConfig config,
  }) async {
    try {
      final connected = await printerRepository.connect(config);
      if (!connected) return false;

      final printed = await printerRepository.printTicket(printJob);

      await printerRepository.disconnect();

      return printed;
    } on PlatformException {
      await printerRepository.disconnect();
      rethrow;
    } catch (_) {
      await printerRepository.disconnect();
      return false;
    }
  }
}
