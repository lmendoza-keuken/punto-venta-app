import 'package:punto_venta_app/features/pos/data/datasources/payment_method_remote_datasource.dart';
import 'package:punto_venta_app/features/pos/domain/entities/payment_method.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/payment_method_repository.dart';

class PaymentMethodRepositoryImpl implements PaymentMethodRepository {
  final PaymentMethodRemoteDatasource remoteDataSource;

  PaymentMethodRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<List<PaymentMethod>> fetchPaymentMethods() async {
    try {
      final models = await remoteDataSource.getPaymentMethods();
      return models.map((m) => m.toEntity()).toList();
    } catch (e) {
      throw Exception('Error al cargar métodos de pago: $e');
    }
  }
}
