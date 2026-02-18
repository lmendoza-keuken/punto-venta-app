import 'package:punto_venta_app/features/pos/domain/entities/payment_method.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/payment_method_repository.dart';

class FetchPaymentMethodsUsecase {
  final PaymentMethodRepository repository;

  FetchPaymentMethodsUsecase(this.repository);

  Future<List<PaymentMethod>> call() async {
    return await repository.fetchPaymentMethods();
  }
  
}