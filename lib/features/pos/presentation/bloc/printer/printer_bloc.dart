import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/print_ticket_usecase.dart';
import 'printer_event.dart';
import 'printer_state.dart';

class PrinterBloc extends Bloc<PrinterEvent, PrinterState> {
  final PrintTicketUsecase printTicketUsecase;

  PrinterBloc({required this.printTicketUsecase}) : super(PrinterInitial()) {
    on<PrintTicket>(_onPrintTicket);
    on<CheckPrinterStatus>(_onCheckPrinterStatus);
  }

  Future<void> _onPrintTicket(
    PrintTicket event,
    Emitter<PrinterState> emit,
  ) async {
    emit(PrinterPrinting());
    
    try {
      final success = await printTicketUsecase(
        printJob: event.printJob,
        config: event.config,
      );
      
      if (success) {
        emit(const PrinterSuccess('Ticket impreso exitosamente'));
      } else {
        emit(const PrinterError('No se pudo conectar con la impresora. Verifica la configuración.'));
      }
    } catch (e) {
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