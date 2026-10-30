import 'package:equatable/equatable.dart';

class MpPaymentResult extends Equatable {
  final String orderId;
  final String paymentId;
  final String referenceId;
  final String paymentDate;
  final String paymentType;
  final bool isAccountMoney;

  const MpPaymentResult({
    required this.orderId,
    required this.paymentId,
    required this.referenceId,
    required this.paymentDate,
    required this.paymentType,
    this.isAccountMoney = true,
  });

  @override
  List<Object?> get props => [
        orderId,
        paymentId,
        referenceId,
        paymentDate,
        paymentType,
        isAccountMoney,
      ];
}

abstract class MercadoPagoQrState extends Equatable {
  const MercadoPagoQrState();

  @override
  List<Object?> get props => [];
}

class MercadoPagoQrInitial extends MercadoPagoQrState {
  const MercadoPagoQrInitial();
}

class MercadoPagoQrLoading extends MercadoPagoQrState {
  const MercadoPagoQrLoading();
}

class MercadoPagoQrGenerated extends MercadoPagoQrState {
  final String qrData;
  final String orderId;

  const MercadoPagoQrGenerated({
    required this.qrData,
    required this.orderId,
  });

  @override
  List<Object?> get props => [qrData, orderId];
}

class MercadoPagoQrPaymentPending extends MercadoPagoQrState {
  const MercadoPagoQrPaymentPending();
}

class MercadoPagoQrPaymentApproved extends MercadoPagoQrState {
  final MpPaymentResult result;

  const MercadoPagoQrPaymentApproved({required this.result});

  @override
  List<Object?> get props => [result];
}

class MercadoPagoQrPaymentRejected extends MercadoPagoQrState {
  final String reason;

  const MercadoPagoQrPaymentRejected({required this.reason});

  @override
  List<Object?> get props => [reason];
}

class MercadoPagoQrExpired extends MercadoPagoQrState {
  const MercadoPagoQrExpired();
}

class MercadoPagoQrError extends MercadoPagoQrState {
  final String message;

  const MercadoPagoQrError({required this.message});

  @override
  List<Object?> get props => [message];
}
