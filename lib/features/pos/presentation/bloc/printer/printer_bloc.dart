import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/utils/confirm_sale_flow_logger.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/print_ticket_usecase.dart';
import 'package:punto_venta_app/features/pos/data/datasources/printer_local_datasource.dart';
import 'printer_event.dart';
import 'printer_state.dart';

class PrinterBloc extends Bloc<PrinterEvent, PrinterState> {
  final PrintTicketUsecase printTicketUsecase;
  final PrinterLocalDataSource printerLocalDataSource;

  PrinterBloc({
    required this.printTicketUsecase,
    required this.printerLocalDataSource,
  }) : super(PrinterInitial()) {
    on<PrintTicket>(_onPrintTicket);
    on<CheckPrinterStatus>(_onCheckPrinterStatus);
  }

  Future<void> _onPrintTicket(
    PrintTicket event,
    Emitter<PrinterState> emit,
  ) async {
    ConfirmSaleFlowLog.step(
      'print_ticket_start',
      detail:
          'ticketId=${event.printJob.ticketId} '
          'template=${event.printJob.templateType} '
          'items=${event.printJob.items.length}',
    );
    emit(PrinterPrinting());

    try {
      ConfirmSaleFlowLog.step('load_printer_config');
      final config = event.config ?? await printerLocalDataSource.getPrinterConfig();
      ConfirmSaleFlowLog.step(
        'print_usecase_start',
        detail: 'ip=${config.ip} port=${config.port}',
      );
      final printSw = Stopwatch()..start();
      final success = await printTicketUsecase(
        printJob: event.printJob,
        config: config,
      );
      printSw.stop();
      ConfirmSaleFlowLog.step(
        'print_usecase_done',
        detail:
            'success=$success printElapsedMs=${printSw.elapsedMilliseconds}',
      );

      if (success) {
        emit(const PrinterSuccess('Ticket impreso exitosamente'));
      } else {
        emit(const PrinterError(
            'No se pudo conectar con la impresora. Verifica la configuración.'));
      }
    } catch (e) {
      ConfirmSaleFlowLog.step('print_ticket_exception', detail: '$e');
      emit(PrinterError('Error de conexión con la impresora: ${e.toString()}'));
    }
  }

  Future<void> _onCheckPrinterStatus(
    CheckPrinterStatus event,
    Emitter<PrinterState> emit,
  ) async {
    // Implementar lógica de verificación de estado
    emit(PrinterDisconnected());
  }
}
