import 'package:equatable/equatable.dart';
import 'package:punto_venta_app/features/app_update/domain/entities/update_check_result.dart';
import 'package:punto_venta_app/features/pos/domain/entities/print_job.dart';

abstract class CheckoutState extends Equatable {
  const CheckoutState();

  @override
  List<Object?> get props => [];
}

class CheckoutInitial extends CheckoutState {
  const CheckoutInitial();
}

class CheckoutProcessing extends CheckoutState {
  const CheckoutProcessing();
}

class CheckoutSuccess extends CheckoutState {
  final PrintJob printJob;
  final UpdateCheckResult? pendingUpdate;

  const CheckoutSuccess({
    required this.printJob,
    this.pendingUpdate,
  });

  @override
  List<Object?> get props => [printJob, pendingUpdate];
}

class CheckoutError extends CheckoutState {
  final String message;

  const CheckoutError({required this.message});

  @override
  List<Object> get props => [message];
}
