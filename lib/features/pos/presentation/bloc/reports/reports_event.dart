import 'package:equatable/equatable.dart';

abstract class ReportsEvent extends Equatable {
  const ReportsEvent();

  @override
  List<Object?> get props => [];
}

class LoadAllReports extends ReportsEvent {
  final bool? includeCreditNotes;

  const LoadAllReports({this.includeCreditNotes});

  @override
  List<Object?> get props => [includeCreditNotes];
}

class LoadMoreReports extends ReportsEvent {
  const LoadMoreReports();
}

class LoadReportsByDateRange extends ReportsEvent {
  final DateTime startDate;
  final DateTime endDate;
  final bool? includeCreditNotes;

  const LoadReportsByDateRange(this.startDate, this.endDate, {this.includeCreditNotes});

  @override
  List<Object?> get props => [startDate, endDate, includeCreditNotes];
}

class LoadDailySummary extends ReportsEvent {
  final DateTime date;
  final bool? includeCreditNotes;

  const LoadDailySummary(this.date, {this.includeCreditNotes});

  @override
  List<Object?> get props => [date, includeCreditNotes];
}

class GenerateCreditNote extends ReportsEvent {
  final String ticketId;

  const GenerateCreditNote(this.ticketId);

  @override
  List<Object> get props => [ticketId];
}
