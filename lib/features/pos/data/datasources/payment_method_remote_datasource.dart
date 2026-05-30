import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:punto_venta_app/core/network/error_handler.dart';
import 'package:punto_venta_app/injection_container.dart' as di;
import '../models/payment_method_model.dart';

part 'payment_method_remote_datasource.g.dart';

@RestApi()
abstract class PaymentMethodService {
  factory PaymentMethodService(Dio dio, {String baseUrl}) = _PaymentMethodService;

  @GET('/payment_methods/')
  Future<List<PaymentMethodModel>> getPaymentMethods();
}

abstract class PaymentMethodRemoteDatasource {
  Future<List<PaymentMethodModel>> getPaymentMethods();
}

class PaymentMethodRemoteDatasourceImpl
    implements PaymentMethodRemoteDatasource {
  PaymentMethodService get _apiService => di.sl<PaymentMethodService>();

  PaymentMethodRemoteDatasourceImpl();

  @override
  Future<List<PaymentMethodModel>> getPaymentMethods() async {
    try {
      return await _apiService.getPaymentMethods();
    } catch (e) {
      throw Exception(ErrorHandler.handleError(e,
          defaultMessage: 'Error al obtener métodos de pago'));
    }
  }
}

