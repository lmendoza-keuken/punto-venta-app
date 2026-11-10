import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:punto_venta_app/core/config/api_config.dart';
import 'package:punto_venta_app/core/network/base_url_failover.dart';
import 'package:punto_venta_app/core/network/error_handler.dart';
import 'package:punto_venta_app/core/utils/app_logger.dart';
import 'package:punto_venta_app/features/pos/data/models/invoice_payload_model.dart';
import 'package:punto_venta_app/features/pos/data/models/tax_model.dart';
import 'package:punto_venta_app/features/pos/data/models/invoice_response_model.dart';
import 'package:punto_venta_app/features/pos/domain/entities/print_job.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/tax_repository.dart';
import 'package:punto_venta_app/injection_container.dart' as di;

part 'invoice_remote_datasource.g.dart';

@RestApi()
abstract class InvoiceService {
  factory InvoiceService(Dio dio, {String baseUrl}) = _InvoiceService;

  @POST('/tickets/')
  Future<dynamic> sendInvoice(@Body() Map<String, dynamic> body);
}

abstract class InvoiceRemoteDataSource {
  Future<InvoiceResponseModel> sendInvoice(PrintJob job);
}

class InvoiceRemoteDataSourceImpl implements InvoiceRemoteDataSource {
  InvoiceService get _apiService => di.sl<InvoiceService>();
  final TaxRepository taxRepository;

  InvoiceRemoteDataSourceImpl({
    required this.taxRepository,
  });

  @override
  Future<InvoiceResponseModel> sendInvoice(PrintJob job) async {
    List<TaxModel> taxes = [];
    try {
      taxes = await taxRepository.getTaxes();
    } catch (e) {
      AppLogger.warn(
        'ConfirmSale: Error al obtener taxes, usando lista vacía: $e',
      );
    }

    final payload = InvoicePayload.fromPrintJob(job, taxes).toJson();
    final urlAtStart = ApiConfig.activeBaseUrl;
    final endpoint = ApiConfig.invoiceUrl;
    final sw = Stopwatch()..start();

    AppLogger.info(
      'ConfirmSale: request start '
      'method=POST path=/tickets/ '
      'baseUrl=$urlAtStart '
      'url=$endpoint '
      'ticketId=${job.ticketId} '
      'total=${job.total} '
      'failoverCandidates=${ApiConfig.baseUrls.length}',
    );

    try {
      final response = await BaseUrlFailover.runWithFailover(() async {
        final attemptUrl = ApiConfig.activeBaseUrl;
        final attemptSw = Stopwatch()..start();
        AppLogger.info(
          'ConfirmSale: HTTP attempt start baseUrl=$attemptUrl url=$attemptUrl/tickets/',
        );
        try {
          final Map<String, dynamic> data =
              await _apiService.sendInvoice(payload);
          attemptSw.stop();
          AppLogger.info(
            'ConfirmSale: HTTP attempt ok '
            'baseUrl=$attemptUrl '
            'elapsedMs=${attemptSw.elapsedMilliseconds}',
          );
          return InvoiceResponseModel.fromJson(data,
              defaultTicketId: job.ticketId);
        } catch (e) {
          attemptSw.stop();
          AppLogger.warn(
            'ConfirmSale: HTTP attempt fail '
            'baseUrl=$attemptUrl '
            'elapsedMs=${attemptSw.elapsedMilliseconds} '
            'error=$e',
          );
          rethrow;
        }
      });

      sw.stop();
      final urlAtEnd = ApiConfig.activeBaseUrl;
      final urlChanged = urlAtStart != urlAtEnd;
      AppLogger.info(
        'ConfirmSale: response ok '
        'elapsedMs=${sw.elapsedMilliseconds} '
        'baseUrlStart=$urlAtStart '
        'baseUrlEnd=$urlAtEnd '
        'urlChanged=$urlChanged '
        'ticketId=${response.ticketId}',
      );
      return response;
    } catch (e) {
      sw.stop();
      final urlAtEnd = ApiConfig.activeBaseUrl;
      final urlChanged = urlAtStart != urlAtEnd;
      AppLogger.error(
        'ConfirmSale: response error '
        'elapsedMs=${sw.elapsedMilliseconds} '
        'baseUrlStart=$urlAtStart '
        'baseUrlEnd=$urlAtEnd '
        'urlChanged=$urlChanged',
        e,
      );
      throw Exception(ErrorHandler.handleError(e,
          defaultMessage: 'Error al enviar factura'));
    }
  }
}
