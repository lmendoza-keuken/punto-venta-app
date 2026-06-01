import 'package:punto_venta_app/features/pos/data/models/invoice_payload_model.dart';
import 'package:punto_venta_app/features/pos/domain/entities/return_reason.dart';
import 'package:punto_venta_app/features/pos/domain/entities/sale_return.dart';

abstract class ReturnsRepository {
  Future<List<ReturnReason>> fetchReturnReasons();
  Future<List<SaleReturn>> fetchReturns({String? date});
  Future<InvoicePayload> processTotalReturn(int saleId, int reasonId);
}
