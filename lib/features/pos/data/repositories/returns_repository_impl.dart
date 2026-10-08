import 'package:punto_venta_app/features/pos/data/datasources/return_reason_local_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/returns_remote_datasource.dart';
import 'package:punto_venta_app/features/pos/data/models/invoice_payload_model.dart';
import 'package:punto_venta_app/features/pos/data/models/partial_return_request_model.dart';
import 'package:punto_venta_app/features/pos/domain/entities/return_reason.dart';
import 'package:punto_venta_app/features/pos/domain/entities/sale_return.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/returns_repository.dart';

class ReturnsRepositoryImpl implements ReturnsRepository {
  final ReturnsRemoteDataSource remoteDataSource;
  final ReturnReasonLocalDataSource localDataSource;

  ReturnsRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<List<ReturnReason>> fetchReturnReasons(
      {bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await localDataSource.getCachedReturnReasons();
      if (cached != null && cached.isNotEmpty) {
        return cached.map((model) => model.toEntity()).toList();
      }
    }

    try {
      final models = await remoteDataSource.getReturnReasons();
      await localDataSource.cacheReturnReasons(models);
      return models.map((model) => model.toEntity()).toList();
    } catch (e) {
      final cached = await localDataSource.getCachedReturnReasons();
      if (cached != null && cached.isNotEmpty) {
        return cached.map((model) => model.toEntity()).toList();
      }
      rethrow;
    }
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
  Future<InvoicePayload> processPartialReturn(
      PartialReturnRequestModel request) async {
    return remoteDataSource.processPartialReturn(request);
  }
}
