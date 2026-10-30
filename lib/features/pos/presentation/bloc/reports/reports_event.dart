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
  final bool refundToMercadoPagoAccount;
  final bool refundToPvsAccount;
  /// Anulación de ticket QR con reembolso en efectivo (asocia in_cash).
  final bool refundInCash;
  final String? mpOrderId;
  final int? pvsPaymentMethodId;
  final int? enterpriseId;
  /// Intentos de refund a cuenta (0 = primero). Tras 1 fallo se puede
  /// reintentar una vez; al segundo fallo solo queda efectivo.
  final int mpRefundAttempt;

  const GenerateCreditNote(
    this.ticketId,
    this.reasonId, {
    this.refundToMercadoPagoAccount = false,
    this.refundToPvsAccount = false,
    this.refundInCash = false,
    this.mpOrderId,
    this.pvsPaymentMethodId,
    this.enterpriseId,
    this.mpRefundAttempt = 0,
  });

  @override
  List<Object?> get props => [
        ticketId,
        reasonId,
        refundToMercadoPagoAccount,
        refundToPvsAccount,
        refundInCash,
        mpOrderId,
        pvsPaymentMethodId,
        enterpriseId,
        mpRefundAttempt,
      ];
}
