import 'package:punto_venta_app/features/pos/data/datasources/stock_dispose_remote_datasource.dart';
import 'package:punto_venta_app/features/pos/data/models/stock_dispose_request_model.dart';
import 'package:punto_venta_app/features/pos/data/models/stock_dispose_response_model.dart';
import 'package:punto_venta_app/features/pos/domain/entities/dispose_reason.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/stock_dispose_repository.dart';

class StockDisposeRepositoryImpl implements StockDisposeRepository {
  final StockDisposeRemoteDataSource remoteDataSource;

  static const List<DisposeReason> _mockReasons = [
    DisposeReason(
      id: 1,
      code: 'VEN',
      firebirdCode: 'MV',
      description: 'Mercadería vencida',
    ),
    DisposeReason(
      id: 2,
      code: 'ROT',
      firebirdCode: 'MV',
      description: 'Mercadería Rota',
    ),
  ];

  StockDisposeRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<DisposeReason>> fetchDisposeReasons() async {
    try {
      final models = await remoteDataSource.getDisposeReasons();
      final enabled =
          models.where((m) => m.enabled).map((m) => m.toEntity()).toList();
      if (enabled.isEmpty) return _mockReasons;
      return enabled;
    } catch (_) {
      return _mockReasons;
    }
  }

  @override
  Future<StockDisposeResponseModel> disposeStock(
      StockDisposeRequestModel request) async {
    return remoteDataSource.disposeStock(request);
  }
}
