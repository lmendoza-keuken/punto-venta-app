import 'package:punto_venta_app/features/pos/data/datasources/stock_dispose_remote_datasource.dart';
import 'package:punto_venta_app/features/pos/data/models/create_dispose_reason_request_model.dart';
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
  Future<DisposeReason> createDisposeReason({
    required String code,
    required String description,
  }) async {
    final model = await remoteDataSource.createDisposeReason(
      CreateDisposeReasonRequestModel(
        code: code,
        description: description,
      ),
    );
    return model.toEntity();
  }

  @override
  Future<void> deleteDisposeReason(int reasonId) {
    return remoteDataSource.deleteDisposeReason(reasonId);
  }

  @override
  Future<StockDisposeResponseModel> disposeStock(
      StockDisposeRequestModel request) async {
    return remoteDataSource.disposeStock(request);
  }
}
