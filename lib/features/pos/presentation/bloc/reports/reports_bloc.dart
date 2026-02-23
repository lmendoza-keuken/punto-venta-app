import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/features/pos/domain/entities/completed_order.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/get_reports_usecase.dart';
import 'reports_event.dart';
import 'reports_state.dart';

class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  final GetReportsUsecase getReportsUsecase;
  
  // Paginación
  int _currentPage = 1;
  final int _pageSize = 10;
  DateTime? _currentStartDate;
  DateTime? _currentEndDate;
  bool _isAllReportsMode = false;

  ReportsBloc({required this.getReportsUsecase}) : super(ReportsInitial()) {
    on<LoadAllReports>(_onLoadAllReports);
    on<LoadMoreReports>(_onLoadMoreReports);
    on<LoadReportsByDateRange>(_onLoadReportsByDateRange);
    on<LoadDailySummary>(_onLoadDailySummary);
    on<PrintTicket>(_onPrintTicket);
  }

  Future<void> _onLoadAllReports(
    LoadAllReports event,
    Emitter<ReportsState> emit,
  ) async {
    emit(ReportsLoading());
    _currentPage = 1;
    _isAllReportsMode = true;
    _currentStartDate = null;
    _currentEndDate = null;
    
    try {
      // Se hace llamado a back si falla se usa local
      try {
        final skip = (_currentPage - 1) * _pageSize;
        final orders =
            await getReportsUsecase.getAllCompletedOrdersFromRemote(skip: skip, limit: _pageSize);
        emit(ReportsLoaded(orders, hasMoreData: orders.length >= _pageSize));
      } catch (remoteError) {
        print('Error fetching from remote, using local data: $remoteError');
        final orders = await getReportsUsecase.getAllCompletedOrders();
        emit(ReportsLoaded(orders, hasMoreData: false));
      }
    } catch (e) {
      emit(ReportsError(e.toString()));
    }
  }

  Future<void> _onLoadMoreReports(
    LoadMoreReports event,
    Emitter<ReportsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ReportsLoaded || 
        currentState.isLoadingMore || 
        !currentState.hasMoreData) {
      return;
    }

    emit(currentState.copyWith(isLoadingMore: true));
    _currentPage++;

    try {
      List<CompletedOrder> newOrders;
      final skip = (_currentPage - 1) * _pageSize;
      
      if (_isAllReportsMode) {
        newOrders = await getReportsUsecase.getAllCompletedOrdersFromRemote(
          skip: skip, 
          limit: _pageSize,
        );
      } else if (_currentStartDate != null) {
        newOrders = await getReportsUsecase.getOrdersByDateRangeFromRemote(
          _currentStartDate!,
          endDate: _currentEndDate,
          skip: skip,
          limit: _pageSize,
        );
      } else {
        // No hay contexto de búsqueda, no hacer nada
        emit(currentState.copyWith(isLoadingMore: false));
        return;
      }

      final updatedOrders = List<CompletedOrder>.from(currentState.orders)..addAll(newOrders);
      
      emit(ReportsLoaded(
        updatedOrders,
        summary: currentState.summary,
        hasMoreData: newOrders.length >= _pageSize,
        isLoadingMore: false,
      ));
    } catch (e) {
      print('Error loading more reports: $e');
      // En caso de error, mantener el estado actual pero quitar el loading
      emit(currentState.copyWith(isLoadingMore: false, hasMoreData: false));
    }
  }

  Future<void> _onLoadReportsByDateRange(
    LoadReportsByDateRange event,
    Emitter<ReportsState> emit,
  ) async {
    emit(ReportsLoading());
    _currentPage = 1;
    _isAllReportsMode = false;
    _currentStartDate = event.startDate;
    _currentEndDate = event.endDate;
    
    try {
      // Se hace llamado a back si falla se usa local
      try {
        final skip = (_currentPage - 1) * _pageSize;
        final orders = await getReportsUsecase.getOrdersByDateRangeFromRemote(
            event.startDate,
            endDate: event.endDate,
            skip: skip,
            limit: _pageSize);
        emit(ReportsLoaded(orders, hasMoreData: orders.length >= _pageSize));
      } catch (remoteError) {
        print('Error fetching from remote, using local data: $remoteError');
        final orders = await getReportsUsecase.getOrdersByDateRange(
            event.startDate, event.endDate);
        emit(ReportsLoaded(orders, hasMoreData: false));
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
    _currentPage = 1;
    _isAllReportsMode = false;
    _currentStartDate = DateTime(event.date.year, event.date.month, event.date.day);
    _currentEndDate = null;
    
    try {
      try {
        final skip = (_currentPage - 1) * _pageSize;
        final summary =
            await getReportsUsecase.getDailySummaryFromRemote(event.date, skip: skip, limit: _pageSize);
        final orders = summary['orders'] as List<CompletedOrder>;
        emit(ReportsLoaded(orders, summary: summary, hasMoreData: orders.length >= _pageSize));
      } catch (remoteError) {
        print('Error fetching from remote, using local data: $remoteError');
        final summary = await getReportsUsecase.getDailySummary(event.date);
        final orders = summary['orders'] as List<CompletedOrder>;
        emit(ReportsLoaded(orders, summary: summary, hasMoreData: false));
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
        emit(ReportsLoaded(
          currentState.orders, 
          summary: currentState.summary,
          hasMoreData: currentState.hasMoreData,
          isLoadingMore: currentState.isLoadingMore,
        ));
      }
    } catch (e) {
      emit(ReportsError('Error al imprimir ticket: $e'));
    }
  }
}
