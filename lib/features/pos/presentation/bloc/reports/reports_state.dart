import 'package:equatable/equatable.dart';
import 'package:punto_venta_app/features/pos/domain/entities/completed_order.dart';

abstract class ReportsState extends Equatable {
  const ReportsState();

  @override
  List<Object> get props => [];
}

class ReportsInitial extends ReportsState {}

class ReportsLoading extends ReportsState {}

class ReportsLoaded extends ReportsState {
  final List<CompletedOrder> orders;
  final Map<String, dynamic>? summary;
  final bool hasMoreData;
  final bool isLoadingMore;

  const ReportsLoaded(
    this.orders, {
    this.summary,
    this.hasMoreData = true,
    this.isLoadingMore = false,
  });

  ReportsLoaded copyWith({
    List<CompletedOrder>? orders,
    Map<String, dynamic>? summary,
    bool? hasMoreData,
    bool? isLoadingMore,
  }) {
    return ReportsLoaded(
      orders ?? this.orders,
      summary: summary ?? this.summary,
      hasMoreData: hasMoreData ?? this.hasMoreData,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object> get props => [orders, summary ?? {}, hasMoreData, isLoadingMore];
}

class ReportsError extends ReportsState {
  final String message;

  const ReportsError(this.message);

  @override
  List<Object> get props => [message];
}

class TicketPrinted extends ReportsState {
  final String message;

  const TicketPrinted(this.message);

  @override
  List<Object> get props => [message];
}
