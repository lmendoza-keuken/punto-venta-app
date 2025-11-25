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

  const ReportsLoaded(this.orders, {this.summary});

  @override
  List<Object> get props => [orders, summary ?? {}];
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
