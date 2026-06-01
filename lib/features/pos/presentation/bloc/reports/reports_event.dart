import 'package:equatable/equatable.dart';

abstract class ReportsEvent extends Equatable {
  const ReportsEvent();

  @override
  List<Object?> get props => [];
}

class LoadAllReports extends ReportsEvent {
  final String? typeCode;

  const LoadAllReports({this.typeCode});

  @override
  List<Object?> get props => [typeCode];
}

class LoadMoreReports extends ReportsEvent {
  const LoadMoreReports();
}

class LoadReportsByDateRange extends ReportsEvent {
  final DateTime startDate;
  final DateTime endDate;
  final String? typeCode;

  const LoadReportsByDateRange(this.startDate, this.endDate, {this.typeCode});

  @override
  List<Object?> get props => [startDate, endDate, typeCode];
}

class LoadDailySummary extends ReportsEvent {
  final DateTime date;
  final String? typeCode;

  const LoadDailySummary(this.date, {this.typeCode});

  @override
  List<Object?> get props => [date, typeCode];
}

class GenerateCreditNote extends ReportsEvent {
  final String ticketId;
  final int reasonId;

  const GenerateCreditNote(this.ticketId, this.reasonId);

  @override
  List<Object> get props => [ticketId, reasonId];
}
