import 'package:equatable/equatable.dart';
import 'package:punto_venta_app/features/pos/data/models/ticket_models/ticket_response_model.dart';
import 'package:punto_venta_app/features/pos/domain/entities/completed_order.dart';

abstract class ReportsState extends Equatable {
  const ReportsState();

  @override
  List<Object> get props => [];
}

class ReportsInitial extends ReportsState {}

class ReportsLoading extends ReportsState {}

class ReportsLoaded extends ReportsState {
  final List<CompletedOrder> tickets;
  final Map<String, dynamic>? summary;
  final bool hasMoreData;
  final bool isLoadingMore;

  const ReportsLoaded(
    this.tickets, {
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
      orders ?? this.tickets,
      summary: summary ?? this.summary,
      hasMoreData: hasMoreData ?? this.hasMoreData,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object> get props => [tickets, summary ?? {}, hasMoreData, isLoadingMore];
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

class CreditNoteGenerated extends ReportsState {
  final String ticketId;
  final String message;

  const CreditNoteGenerated({
    required this.ticketId,
    required this.message,
  });

  @override
  List<Object> get props => [ticketId, message];
}

class CreditNoteGenerationError extends ReportsState {
  final String ticketId;
  final String message;

  const CreditNoteGenerationError({
    required this.ticketId,
    required this.message,
  });

  @override
  List<Object> get props => [ticketId, message];
}
