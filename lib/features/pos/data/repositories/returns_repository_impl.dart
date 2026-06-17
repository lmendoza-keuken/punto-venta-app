import 'package:punto_venta_app/features/pos/data/datasources/returns_remote_datasource.dart';
import 'package:punto_venta_app/features/pos/data/models/invoice_payload_model.dart';
import 'package:punto_venta_app/features/pos/data/models/partial_return_request_model.dart';
import 'package:punto_venta_app/features/pos/domain/entities/return_reason.dart';
import 'package:punto_venta_app/features/pos/domain/entities/sale_return.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/returns_repository.dart';

class ReturnsRepositoryImpl implements ReturnsRepository {
  final ReturnsRemoteDataSource remoteDataSource;

  ReturnsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<ReturnReason>> fetchReturnReasons() async {
    final models = await remoteDataSource.getReturnReasons();
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<SaleReturn>> fetchReturns({String? date}) async {
    final models = await remoteDataSource.getReturns(date: date);
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<InvoicePayload> processTotalReturn(int saleId, int reasonId) async {
    return remoteDataSource.processTotalReturn(saleId, reasonId);
  }

  @override
  Future<InvoicePayload> processPartialReturn(PartialReturnRequestModel request) async {
    return remoteDataSource.processPartialReturn(request);
  }
}
