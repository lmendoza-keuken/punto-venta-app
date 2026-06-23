import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:punto_venta_app/core/network/error_handler.dart';
import 'package:punto_venta_app/features/pos/data/models/invoice_payload_model.dart';
import 'package:punto_venta_app/injection_container.dart' as di;

part 'completed_orders_remote_datasource.g.dart';

@RestApi()
abstract class CompletedOrdersService {
  factory CompletedOrdersService(Dio dio, {String baseUrl}) =
      _CompletedOrdersService;

  @GET('/tickets/')
  Future<List<InvoicePayload>> getAllTickets(
      {@Query('skip') int skip = 0,
      @Query('limit') int limit = 10,
      @Query('type_code') String? typeCode});

  @GET('/tickets/')
  Future<List<InvoicePayload>> getTicketsByDateRange(
      {@Query('start_date') required String startDate,
      @Query('end_date') String? endDate,
      @Query('skip') int skip = 0,
      @Query('limit') int limit = 10,
      @Query('type_code') String? typeCode});

  @GET('/tickets/{id}')
  Future<InvoicePayload> getTicketById(@Path('id') String id);
}

abstract class CompletedOrdersRemoteDataSource {
  Future<List<InvoicePayload>> getAllTickets(
      {int skip = 0, int limit = 10, String? typeCode});
  Future<List<InvoicePayload>> getTicketsByDateRange(DateTime startDate,
      {DateTime? endDate, int skip = 0, int limit = 10, String? typeCode});
  Future<InvoicePayload?> getTicketById(String ticketId);
}

class CompletedOrdersRemoteDataSourceImpl
    implements CompletedOrdersRemoteDataSource {
  CompletedOrdersService get _apiService => di.sl<CompletedOrdersService>();

  CompletedOrdersRemoteDataSourceImpl();

  @override
  Future<List<InvoicePayload>> getAllTickets(
      {int skip = 0, int limit = 10, String? typeCode}) async {
    try {
      return await _apiService.getAllTickets(
          skip: skip, limit: limit, typeCode: typeCode);
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
      String? typeCode}) async {
    try {
      return await _apiService.getTicketsByDateRange(
        startDate: _formatDateYYYYMMDD(startDate),
        endDate: endDate != null ? _formatDateYYYYMMDD(endDate) : null,
        skip: skip,
        limit: limit,
        typeCode: typeCode,
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

  String _formatDateYYYYMMDD(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
