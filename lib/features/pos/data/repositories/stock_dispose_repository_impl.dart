import 'package:punto_venta_app/features/pos/data/datasources/stock_dispose_remote_datasource.dart';
import 'package:punto_venta_app/features/pos/data/models/product_model.dart';
import 'package:punto_venta_app/features/pos/data/models/stock_dispose_request_model.dart';
import 'package:punto_venta_app/features/pos/domain/entities/dispose_reason.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/stock_dispose_repository.dart';

class StockDisposeRepositoryImpl implements StockDisposeRepository {
  final StockDisposeRemoteDataSource remoteDataSource;

  static const List<DisposeReason> _mockReasons = [
    DisposeReason(id: 1, description: 'Rotura'),
    DisposeReason(id: 2, description: 'Vencimiento'),
  ];

  StockDisposeRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<DisposeReason>> fetchDisposeReasons() async {
    try {
      final models = await remoteDataSource.getDisposeReasons();
      if (models.isEmpty) return _mockReasons;
      return models.map((m) => m.toEntity()).toList();
    } catch (_) {
      return _mockReasons;
    }
  }

  @override
  Future<List<ProductModel>> disposeStock(
      StockDisposeRequestModel request) async {
    return remoteDataSource.disposeStock(request);
  }
}
