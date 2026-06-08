import '../../data/datasources/returns_remote_datasource.dart';
import '../../data/models/return_reason_model.dart';

class GetReturnReasonsUseCase {
  final ReturnsRemoteDataSource dataSource;

  GetReturnReasonsUseCase(this.dataSource);

  Future<List<ReturnReasonModel>> call() async {
    return await dataSource.getReturnReasons();
  }
}
