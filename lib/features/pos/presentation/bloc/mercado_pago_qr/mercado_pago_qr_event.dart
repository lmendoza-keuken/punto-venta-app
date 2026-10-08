import 'package:equatable/equatable.dart';

abstract class MercadoPagoQrEvent extends Equatable {
  const MercadoPagoQrEvent();

  @override
  List<Object?> get props => [];
}

class GenerateMercadoPagoQr extends MercadoPagoQrEvent {
  final double amount;
  final String? description;
  final String? externalReference;

  const GenerateMercadoPagoQr({
    required this.amount,
    this.description,
    this.externalReference,
  });

  @override
  List<Object?> get props => [amount, description, externalReference];
}

class CheckMercadoPagoStatus extends MercadoPagoQrEvent {
  final String orderId;

  const CheckMercadoPagoStatus({required this.orderId});

  @override
  List<Object?> get props => [orderId];
}

class CancelMercadoPagoOrder extends MercadoPagoQrEvent {
  final String orderId;

  const CancelMercadoPagoOrder({required this.orderId});

  @override
  List<Object?> get props => [orderId];
}

class ResetMercadoPagoQr extends MercadoPagoQrEvent {
  const ResetMercadoPagoQr();
}

class ExpireMercadoPagoQr extends MercadoPagoQrEvent {
  const ExpireMercadoPagoQr();
}
