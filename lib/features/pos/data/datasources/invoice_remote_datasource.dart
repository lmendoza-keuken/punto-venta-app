import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:punto_venta_app/core/config/api_config.dart';
import 'package:punto_venta_app/core/network/base_url_failover.dart';
import 'package:punto_venta_app/core/network/error_handler.dart';
import 'package:punto_venta_app/core/utils/app_logger.dart';
import 'package:punto_venta_app/core/utils/confirm_sale_flow_logger.dart';
import 'package:punto_venta_app/features/pos/data/models/invoice_payload_model.dart';
import 'package:punto_venta_app/features/pos/data/models/invoice_response_model.dart';
import 'package:punto_venta_app/features/pos/domain/entities/print_job.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/tax_repository.dart';
import 'package:punto_venta_app/injection_container.dart' as di;

part 'invoice_remote_datasource.g.dart';

@RestApi()
abstract class InvoiceService {
  factory InvoiceService(Dio dio, {String baseUrl}) = _InvoiceService;

  @POST('tickets/')
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
    ConfirmSaleFlowLog.step('invoice_ds_start');
    ConfirmSaleFlowLog.step('load_taxes_for_payload_from_cache');
    final taxes = await taxRepository.getCachedTaxes();
    ConfirmSaleFlowLog.step(
      'taxes_cache_ready',
      detail: 'count=${taxes.length} source=local_cache',
    );
    if (taxes.isEmpty) {
      AppLogger.warn(
        'ConfirmSale: cache de taxes vacío — payload usará IDs por porcentaje',
      );
    }

    ConfirmSaleFlowLog.step(
      'map_invoice_payload_start',
      detail:
          'ticketId=${job.ticketId} items=${job.logItems.length} '
          'total=${job.total}',
    );
    final mapSw = Stopwatch()..start();
    final payload = InvoicePayload.fromPrintJob(job, taxes).toJson();
    mapSw.stop();
    ConfirmSaleFlowLog.step(
      'map_invoice_payload_done',
      detail:
          'mapElapsedMs=${mapSw.elapsedMilliseconds} '
          'payloadKeys=${payload.keys.join(",")} '
          'paymentMethods=${(payload['paymentMethods'] as List?)?.length ?? 0} '
          'items=${(payload['items'] as List?)?.length ?? 0}',
    );

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
    ConfirmSaleFlowLog.step(
      'http_request_start',
      detail: 'url=$endpoint baseUrl=$urlAtStart',
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
      ConfirmSaleFlowLog.step(
        'http_request_done',
        detail:
            'requestElapsedMs=${sw.elapsedMilliseconds} '
            'urlChanged=$urlChanged '
            'baseUrlEnd=$urlAtEnd '
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
      ConfirmSaleFlowLog.step(
        'http_request_error',
        detail:
            'requestElapsedMs=${sw.elapsedMilliseconds} '
            'urlChanged=$urlChanged',
      );
      throw Exception(ErrorHandler.handleError(e,
          defaultMessage: 'Error al enviar factura'));
    }
  }
}
