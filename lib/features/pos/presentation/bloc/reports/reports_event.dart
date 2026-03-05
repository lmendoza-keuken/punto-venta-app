import 'package:equatable/equatable.dart';

abstract class ReportsEvent extends Equatable {
  const ReportsEvent();

  @override
  List<Object?> get props => [];
}

class LoadAllReports extends ReportsEvent {
  final bool? onlySales;

  const LoadAllReports({this.onlySales});

  @override
  List<Object?> get props => [onlySales];
}

class LoadMoreReports extends ReportsEvent {
  const LoadMoreReports();
}

class LoadReportsByDateRange extends ReportsEvent {
  final DateTime startDate;
  final DateTime endDate;
  final bool? onlySales;

  const LoadReportsByDateRange(this.startDate, this.endDate, {this.onlySales});

  @override
  List<Object?> get props => [startDate, endDate, onlySales];
}

class LoadDailySummary extends ReportsEvent {
  final DateTime date;
  final bool? onlySales;

  const LoadDailySummary(this.date, {this.onlySales});

  @override
  List<Object?> get props => [date, onlySales];
}

class GenerateCreditNote extends ReportsEvent {
  final String ticketId;

  const GenerateCreditNote(this.ticketId);

  @override
  List<Object> get props => [ticketId];
}
