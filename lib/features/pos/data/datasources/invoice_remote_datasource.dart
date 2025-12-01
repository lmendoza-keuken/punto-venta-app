import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:punto_venta_app/core/config/api_config.dart';
import 'package:punto_venta_app/features/pos/data/models/invoice_payload_model.dart';
import 'package:punto_venta_app/features/pos/domain/entities/print_job.dart';

abstract class InvoiceRemoteDataSource {
  Future<bool> sendInvoice(PrintJob job);
}

class InvoiceRemoteDataSourceImpl implements InvoiceRemoteDataSource {
  final http.Client client;
  final Duration timeout;

  InvoiceRemoteDataSourceImpl({
    required this.client,
    this.timeout = const Duration(seconds: 10),
  });

  @override
  Future<bool> sendInvoice(PrintJob job) async {
    final url = ApiConfig.invoiceUrl;

    if (url.isEmpty) {
      await Future.delayed(const Duration(seconds: 3));
      return true;
    }

    final uri = Uri.parse(url);

    final payload = InvoicePayload.fromPrintJob(job).toJson();

    try {
      final response = await client
          .post(
            uri,
            headers: {
              HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8',
            },
            body: json.encode(payload),
          )
          .timeout(timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        throw Exception(
            'Invoice API error: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
