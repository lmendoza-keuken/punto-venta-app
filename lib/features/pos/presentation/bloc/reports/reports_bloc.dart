import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/features/pos/domain/entities/completed_order.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/get_reports_usecase.dart';
import 'reports_event.dart';
import 'reports_state.dart';

class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  final GetReportsUsecase getReportsUsecase;

  ReportsBloc({required this.getReportsUsecase}) : super(ReportsInitial()) {
    on<LoadAllReports>(_onLoadAllReports);
    on<LoadReportsByDateRange>(_onLoadReportsByDateRange);
    on<LoadDailySummary>(_onLoadDailySummary);
    on<PrintTicket>(_onPrintTicket);
  }

  Future<void> _onLoadAllReports(
    LoadAllReports event,
    Emitter<ReportsState> emit,
  ) async {
    emit(ReportsLoading());
    try {
      // Se hace llamado a back si falla se usa local
      try {
        final orders =
            await getReportsUsecase.getAllCompletedOrdersFromRemote();
        emit(ReportsLoaded(orders));
      } catch (remoteError) {
        print('Error fetching from remote, using local data: $remoteError');
        final orders = await getReportsUsecase.getAllCompletedOrders();
        emit(ReportsLoaded(orders));
      }
    } catch (e) {
      emit(ReportsError(e.toString()));
    }
  }

  Future<void> _onLoadReportsByDateRange(
    LoadReportsByDateRange event,
    Emitter<ReportsState> emit,
  ) async {
    emit(ReportsLoading());
    try {
      // Se hace llamado a back si falla se usa local
      try {
        final orders = await getReportsUsecase.getOrdersByDateRangeFromRemote(
            event.startDate,
            endDate: event.endDate);
        emit(ReportsLoaded(orders));
      } catch (remoteError) {
        print('Error fetching from remote, using local data: $remoteError');
        final orders = await getReportsUsecase.getOrdersByDateRange(
            event.startDate, event.endDate);
        emit(ReportsLoaded(orders));
      }
    } catch (e) {
      emit(ReportsError(e.toString()));
    }
  }

  Future<void> _onLoadDailySummary(
    LoadDailySummary event,
    Emitter<ReportsState> emit,
  ) async {
    emit(ReportsLoading());
    try {
      try {
        final summary =
            await getReportsUsecase.getDailySummaryFromRemote(event.date);
        final orders = summary['orders'] as List<CompletedOrder>;
        emit(ReportsLoaded(orders, summary: summary));
      } catch (remoteError) {
        print('Error fetching from remote, using local data: $remoteError');
        final summary = await getReportsUsecase.getDailySummary(event.date);
        final orders = summary['orders'] as List<CompletedOrder>;
        emit(ReportsLoaded(orders, summary: summary));
      }
    } catch (e) {
      emit(ReportsError(e.toString()));
    }
  }

  Future<void> _onPrintTicket(
    PrintTicket event,
    Emitter<ReportsState> emit,
  ) async {
    try {
      // Simular impresión de ticket
      await Future.delayed(const Duration(seconds: 1));
      emit(const TicketPrinted('Ticket reimpreso exitosamente'));

      // Volver al estado anterior si había órdenes cargadas
      if (state is ReportsLoaded) {
        final currentState = state as ReportsLoaded;
        emit(ReportsLoaded(currentState.orders, summary: currentState.summary));
      }
    } catch (e) {
      emit(ReportsError('Error al imprimir ticket: $e'));
    }
  }
}
