import 'package:equatable/equatable.dart';

class PvsPaymentResult extends Equatable {
  final String orderId;
  final String paymentId;
  final String paymentDate;
  final String paymentStatus;
  final String wallet;

  const PvsPaymentResult({
    required this.orderId,
    required this.paymentId,
    required this.paymentDate,
    required this.paymentStatus,
    this.wallet = '',
  });

  @override
  List<Object?> get props =>
      [orderId, paymentId, paymentDate, paymentStatus, wallet];
}

abstract class PvsQrState extends Equatable {
  const PvsQrState();

  @override
  List<Object?> get props => [];
}

class PvsQrInitial extends PvsQrState {
  const PvsQrInitial();
}

class PvsQrLoading extends PvsQrState {
  const PvsQrLoading();
}

class PvsQrGenerated extends PvsQrState {
  final String qrId;
  final String? qrRaw;
  final String? qrImageBase64;
  final int secondsRemaining;

  const PvsQrGenerated({
    required this.qrId,
    required this.secondsRemaining,
    this.qrRaw,
    this.qrImageBase64,
  });

  @override
  List<Object?> get props => [qrId, qrRaw, qrImageBase64, secondsRemaining];
}

class PvsQrPaymentPending extends PvsQrState {
  final String qrId;
  final String? qrRaw;
  final String? qrImageBase64;
  final int secondsRemaining;

  const PvsQrPaymentPending({
    required this.qrId,
    required this.secondsRemaining,
    this.qrRaw,
    this.qrImageBase64,
  });

  @override
  List<Object?> get props => [qrId, qrRaw, qrImageBase64, secondsRemaining];
}

class PvsQrPaymentApproved extends PvsQrState {
  final PvsPaymentResult result;

  const PvsQrPaymentApproved({required this.result});

  @override
  List<Object?> get props => [result];
}

class PvsQrPaymentRejected extends PvsQrState {
  final String reason;

  const PvsQrPaymentRejected({required this.reason});

  @override
  List<Object?> get props => [reason];
}

class PvsQrExpired extends PvsQrState {
  const PvsQrExpired();
}

class PvsQrError extends PvsQrState {
  final String message;

  const PvsQrError({required this.message});

  @override
  List<Object?> get props => [message];
}
