import 'package:dio/dio.dart';
import 'package:punto_venta_app/core/config/api_config.dart';
import 'package:punto_venta_app/core/network/dio_client.dart';
import 'package:punto_venta_app/features/pos/data/models/invoice_payload_model.dart';
import 'package:punto_venta_app/features/pos/domain/entities/print_job.dart';
import 'package:punto_venta_app/features/auth/data/datasources/auth_local_datasources.dart';
import 'package:punto_venta_app/injection_container.dart' as di;

abstract class InvoiceRemoteDataSource {
  Future<bool> sendInvoice(PrintJob job);
}

class InvoiceRemoteDataSourceImpl implements InvoiceRemoteDataSource {
  final Dio _dio;
  final Duration timeout;

  InvoiceRemoteDataSourceImpl({
    Dio? dio,
    this.timeout = const Duration(seconds: 15),
  }) : _dio = dio ?? DioClient.instance;

  @override
  Future<bool> sendInvoice(PrintJob job) async {
    final url = ApiConfig.invoiceUrl;

    if (url.isEmpty) {
      print('⚠️ [INVOICE] URL vacía, simulando envío exitoso');
      await Future.delayed(const Duration(seconds: 1));
      return true;
    }

    final localDs = di.sl<AuthLocalDataSource>();
    final token = await localDs.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('No hay token de autenticación disponible');
    }

    final payload = InvoicePayload.fromPrintJob(job).toJson();

    try {
      final response = await _dio.post(
        url,
        data: payload,
        options: Options(
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Authorization': 'Bearer $token',
          },
          sendTimeout: timeout,
          receiveTimeout: timeout,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Invoice API error: ${response.statusCode} ${response.data}',
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
            'Timeout al enviar factura después de ${timeout.inSeconds}s');
      } else if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception(
            'Tiempo de conexión agotado. Verifica que el servidor esté activo en $url');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception(
            'Error de conexión. Verifica la red y que el servidor esté disponible');
      } else if (e.response != null) {
        throw Exception(
            'Error al enviar factura: ${e.response?.statusCode} - ${e.response?.data}');
      } else {
        throw Exception('Error de conexión al enviar factura: ${e.message}');
      }
    } catch (e) {
      throw Exception('Error inesperado al enviar factura: $e');
    }
  }
}
