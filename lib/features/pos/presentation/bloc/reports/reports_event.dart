import 'package:equatable/equatable.dart';

abstract class ReportsEvent extends Equatable {
  const ReportsEvent();

  @override
  List<Object> get props => [];
}

class LoadAllReports extends ReportsEvent {}

class LoadMoreReports extends ReportsEvent {
  const LoadMoreReports();
}

class LoadReportsByDateRange extends ReportsEvent {
  final DateTime startDate;
  final DateTime endDate;

  const LoadReportsByDateRange(this.startDate, this.endDate);

  @override
  List<Object> get props => [startDate, endDate];
}

class LoadDailySummary extends ReportsEvent {
  final DateTime date;

  const LoadDailySummary(this.date);

  @override
  List<Object> get props => [date];
}

class GenerateCreditNote extends ReportsEvent {
  final String ticketId;

  const GenerateCreditNote(this.ticketId);

  @override
  List<Object> get props => [ticketId];
}
