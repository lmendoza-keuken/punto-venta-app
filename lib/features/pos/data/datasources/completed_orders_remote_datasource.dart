import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:punto_venta_app/core/config/api_config.dart';
import 'package:punto_venta_app/core/network/dio_client.dart';
import 'package:punto_venta_app/core/network/error_handler.dart';
import 'package:punto_venta_app/features/pos/data/models/invoice_payload_model.dart';
import 'package:punto_venta_app/features/auth/data/datasources/auth_local_datasources.dart';
import 'package:punto_venta_app/injection_container.dart' as di;

part 'completed_orders_remote_datasource.g.dart';

@RestApi()
abstract class CompletedOrdersService {
  factory CompletedOrdersService(Dio dio, {String baseUrl}) = _CompletedOrdersService;

  @GET('/tickets/')
  Future<List<InvoicePayload>> getAllTickets(
      {@Query('skip') int skip = 0,
      @Query('limit') int limit = 10,
      @Query('only_sales') bool? onlySales});

  @GET('/tickets/')
  Future<List<InvoicePayload>> getTicketsByDateRange(
      {@Query('start_date') required String startDate,
      @Query('end_date') String? endDate,
      @Query('skip') int skip = 0,
      @Query('limit') int limit = 10,
      @Query('only_sales') bool? onlySales});

  @GET('/tickets/{id}')
  Future<InvoicePayload> getTicketById(@Path('id') String id);

  @POST('/tickets/{id}/nota-credito')
  Future<InvoicePayload> convertToCreditNote(@Path('id') String id);
}

abstract class CompletedOrdersRemoteDataSource {
  Future<List<InvoicePayload>> getAllTickets(
      {int skip = 0, int limit = 10, bool? onlySales});
  Future<List<InvoicePayload>> getTicketsByDateRange(DateTime startDate,
      {DateTime? endDate, int skip = 0, int limit = 10, bool? onlySales});
  Future<InvoicePayload?> getTicketById(String ticketId);
  Future<InvoicePayload?> convertToCreditNote(String ticketId);
}

class CompletedOrdersRemoteDataSourceImpl
    implements CompletedOrdersRemoteDataSource {
  CompletedOrdersService get _apiService => di.sl<CompletedOrdersService>();

  CompletedOrdersRemoteDataSourceImpl();

  @override
  Future<List<InvoicePayload>> getAllTickets(
      {int skip = 0, int limit = 10, bool? onlySales}) async {
    try {
      return await _apiService.getAllTickets(
          skip: skip, limit: limit, onlySales: onlySales);
    } catch (e) {
      throw Exception(ErrorHandler.handleError(e,
          defaultMessage: 'Error al obtener órdenes'));
    }
  }

  @override
  Future<List<InvoicePayload>> getTicketsByDateRange(DateTime startDate,
      {DateTime? endDate,
      int skip = 0,
      int limit = 10,
      bool? onlySales}) async {
    try {
      return await _apiService.getTicketsByDateRange(
        startDate: _formatDateYYYYMMDD(startDate),
        endDate: endDate != null ? _formatDateYYYYMMDD(endDate) : null,
        skip: skip,
        limit: limit,
        onlySales: onlySales,
      );
    } catch (e) {
      throw Exception(ErrorHandler.handleError(e,
          defaultMessage: 'Error al obtener órdenes por fecha'));
    }
  }

  @override
  Future<InvoicePayload?> getTicketById(String orderId) async {
    try {
      return await _apiService.getTicketById(orderId);
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) {
        return null;
      }
      throw Exception(ErrorHandler.handleError(e,
          defaultMessage: 'Error al obtener orden'));
    }
  }

  @override
  Future<InvoicePayload?> convertToCreditNote(String ticketId) async {
    try {
      return await _apiService.convertToCreditNote(ticketId);
    } catch (e) {
      throw Exception(ErrorHandler.handleError(e,
          defaultMessage: 'Error al convertir a nota de crédito'));
    }
  }

  String _formatDateYYYYMMDD(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
