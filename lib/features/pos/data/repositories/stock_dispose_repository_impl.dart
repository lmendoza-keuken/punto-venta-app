import 'package:punto_venta_app/features/pos/data/datasources/stock_dispose_remote_datasource.dart';
import 'package:punto_venta_app/features/pos/data/models/stock_dispose_request_model.dart';
import 'package:punto_venta_app/features/pos/data/models/stock_dispose_response_model.dart';
import 'package:punto_venta_app/features/pos/domain/entities/dispose_reason.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/stock_dispose_repository.dart';

class StockDisposeRepositoryImpl implements StockDisposeRepository {
  final StockDisposeRemoteDataSource remoteDataSource;

  StockDisposeRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<DisposeReason>> fetchDisposeReasons() async {
    final models = await remoteDataSource.getDisposeReasons();
    return models.where((m) => m.enabled).map((m) => m.toEntity()).toList();
  }

  @override
  Future<StockDisposeResponseModel> disposeStock(
      StockDisposeRequestModel request) async {
    return remoteDataSource.disposeStock(request);
  }
}
