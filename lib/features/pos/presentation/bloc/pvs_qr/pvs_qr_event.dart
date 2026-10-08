import 'package:equatable/equatable.dart';

abstract class PvsQrEvent extends Equatable {
  const PvsQrEvent();

  @override
  List<Object?> get props => [];
}

class GeneratePvsQr extends PvsQrEvent {
  final double amount;
  final int paymentMethodId;
  final String? description;
  final String? externalId;

  const GeneratePvsQr({
    required this.amount,
    required this.paymentMethodId,
    this.description,
    this.externalId,
  });

  @override
  List<Object?> get props => [amount, paymentMethodId, description, externalId];
}

class CheckPvsStatus extends PvsQrEvent {
  final String qrId;

  const CheckPvsStatus({required this.qrId});

  @override
  List<Object?> get props => [qrId];
}

class CancelPvsQrSession extends PvsQrEvent {
  const CancelPvsQrSession();
}

class ResetPvsQr extends PvsQrEvent {
  const ResetPvsQr();
}

class ExpirePvsQr extends PvsQrEvent {
  const ExpirePvsQr();
}

class TickPvsQrCountdown extends PvsQrEvent {
  const TickPvsQrCountdown();
}
