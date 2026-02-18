import 'package:punto_venta_app/features/pos/domain/entities/payment_method.dart';

abstract class PaymentMethodRepository {
  Future<List<PaymentMethod>> fetchPaymentMethods();
}