import 'package:equatable/equatable.dart';
import '../../../domain/entities/payment_method.dart';

abstract class PaymentMethodsEvent extends Equatable {
  const PaymentMethodsEvent();
  @override
  List<Object?> get props => [];
}

class LoadPaymentMethods extends PaymentMethodsEvent {}

class SelectPaymentMethodEvent extends PaymentMethodsEvent {
  final PaymentMethod? paymentMethod;
  const SelectPaymentMethodEvent(this.paymentMethod);
  @override
  List<Object?> get props => [paymentMethod];
}
