import 'package:dio/dio.dart';
import 'package:punto_venta_app/core/config/api_config.dart';
import 'package:punto_venta_app/core/network/dio_client.dart';
import 'package:punto_venta_app/features/pos/data/models/invoice_payload_model.dart';
import 'package:punto_venta_app/features/auth/data/datasources/auth_local_datasources.dart';
import 'package:punto_venta_app/features/pos/data/models/ticket_models/ticket_response_model.dart';
import 'package:punto_venta_app/injection_container.dart' as di;

abstract class CompletedOrdersRemoteDataSource {
  Future<List<InvoicePayload>> getAllTickets({int skip = 0, int limit = 10});
  Future<List<InvoicePayload>> getTicketsByDateRange(
      DateTime startDate, {DateTime? endDate, int skip = 0, int limit = 10});
  Future<InvoicePayload?> getTicketById(String ticketId);
  Future<InvoicePayload?> convertToCreditNote(String ticketId);
}

class CompletedOrdersRemoteDataSourceImpl
    implements CompletedOrdersRemoteDataSource {
  final Dio _dio;
  final Duration timeout;

  CompletedOrdersRemoteDataSourceImpl({
    Dio? dio,
    this.timeout = const Duration(seconds: 15),
  }) : _dio = dio ?? DioClient.instance;

  @override
  Future<List<InvoicePayload>> getAllTickets({int skip = 0, int limit = 10}) async {
    final url = ApiConfig.invoiceUrl;

    if (url.isEmpty || ApiConfig.invoiceUrl.isEmpty) {
      print('⚠️ [ORDERS] URL vacía, retornando lista vacía');
      return [];
    }

    final localDs = di.sl<AuthLocalDataSource>();
    final token = await localDs.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('No hay token de autenticación disponible');
    }

    try {
      final response = await _dio.get(
        url,
        queryParameters: {
          'skip': skip,
          'limit': limit,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Authorization': 'Bearer $token',
          },
          receiveTimeout: timeout,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as List;
        return data
            .map(
                (json) => InvoicePayload.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Orders API error: ${response.statusCode} ${response.data}',
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
            'Timeout al obtener órdenes después de ${timeout.inSeconds}s');
      } else if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception(
            'Tiempo de conexión agotado. Verifica que el servidor esté activo en $url');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception(
            'Error de conexión. Verifica la red y que el servidor esté disponible');
      } else if (e.response != null) {
        throw Exception(
            'Error al obtener órdenes: ${e.response?.statusCode} - ${e.response?.data}');
      } else {
        throw Exception('Error de conexión al obtener órdenes: ${e.message}');
      }
    } catch (e) {
      throw Exception('Error inesperado al obtener órdenes: $e');
    }
  }

  @override
  Future<List<InvoicePayload>> getTicketsByDateRange(
      DateTime startDate, {DateTime? endDate, int skip = 0, int limit = 10}) async {
    final url = ApiConfig.invoiceUrl;

    if (url.isEmpty || ApiConfig.invoiceUrl.isEmpty) {
      print('⚠️ [ORDERS] URL vacía, retornando lista vacía');
      return [];
    }

    final localDs = di.sl<AuthLocalDataSource>();
    final token = await localDs.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('No hay token de autenticación disponible');
    }

    final queryParams = <String, dynamic>{
      'start_date': _formatDateYYYYMMDD(startDate),
      'skip': skip,
      'limit': limit,
    };
    if (endDate != null) {
      queryParams['end_date'] = _formatDateYYYYMMDD(endDate);
    }

    try {
      final response = await _dio.get(
        url,
        queryParameters: queryParams,
        options: Options(
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Authorization': 'Bearer $token',
          },
          receiveTimeout: timeout,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as List;
        return data
            .map(
                (json) => InvoicePayload.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Orders API error: ${response.statusCode} ${response.data}',
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
            'Timeout al obtener órdenes después de ${timeout.inSeconds}s');
      } else if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception(
            'Tiempo de conexión agotado. Verifica que el servidor esté activo en $url');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception(
            'Error de conexión. Verifica la red y que el servidor esté disponible');
      } else if (e.response != null) {
        throw Exception(
            'Error al obtener órdenes: ${e.response?.statusCode} - ${e.response?.data}');
      } else {
        throw Exception('Error de conexión al obtener órdenes: ${e.message}');
      }
    } catch (e) {
      throw Exception('Error inesperado al obtener órdenes: $e');
    }
  }

  @override
  Future<InvoicePayload?> getTicketById(String orderId) async {
    final url = '${ApiConfig.invoiceUrl}$orderId';

    if (url.isEmpty || ApiConfig.invoiceUrl.isEmpty) {
      print('⚠️ [ORDERS] URL vacía, retornando null');
      return null;
    }

    final localDs = di.sl<AuthLocalDataSource>();
    final token = await localDs.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('No hay token de autenticación disponible');
    }

    try {
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Authorization': 'Bearer $token',
          },
          receiveTimeout: timeout,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200) {
        return InvoicePayload.fromJson(response.data as Map<String, dynamic>);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Orders API error: ${response.statusCode} ${response.data}',
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
            'Timeout al obtener orden después de ${timeout.inSeconds}s');
      } else if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception(
            'Tiempo de conexión agotado. Verifica que el servidor esté activo en $url');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception(
            'Error de conexión. Verifica la red y que el servidor esté disponible');
      } else if (e.response != null) {
        throw Exception(
            'Error al obtener orden: ${e.response?.statusCode} - ${e.response?.data}');
      } else {
        throw Exception('Error de conexión al obtener orden: ${e.message}');
      }
    } catch (e) {
      throw Exception('Error inesperado al obtener orden: $e');
    }
  }

  @override
  Future<InvoicePayload?> convertToCreditNote(String ticketId) async {
    final url = '${ApiConfig.invoiceUrl}$ticketId/nota-credito';

    if (url.isEmpty || ApiConfig.invoiceUrl.isEmpty) {
      print('⚠️ [CREDIT NOTE] URL vacía, no se puede convertir a nota de crédito');
      return null;
    }

    final localDs = di.sl<AuthLocalDataSource>();
    final token = await localDs.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('No hay token de autenticación disponible');
    }

    try {
      final response = await _dio.post(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Authorization': 'Bearer $token',
          },
          receiveTimeout: timeout,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200) {
        print('✅ [CREDIT NOTE] Nota de crédito generada correctamente para el ticket $ticketId');
        return InvoicePayload.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Credit Note API error: ${response.statusCode} ${response.data}',
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
            'Timeout al convertir a nota de crédito después de ${timeout.inSeconds}s');
      } else if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception(
            'Tiempo de conexión agotado. Verifica que el servidor esté activo en $url');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception(
            'Error de conexión. Verifica la red y que el servidor esté disponible');
      } else if (e.response != null) {
        throw Exception(
            'Error al convertir a nota de crédito: ${e.response?.statusCode} - ${e.response?.data}');
      } else {
        throw Exception('Error de conexión al convertir a nota de crédito: ${e.message}');
      }
    } catch (e) {
      throw Exception('Error inesperado al convertir a nota de crédito: $e');
    }
  }

  String _formatDateYYYYMMDD(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
