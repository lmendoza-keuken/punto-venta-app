import 'package:punto_venta_app/features/pos/data/datasources/mercado_pago_local_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/mercado_pago_remote_datasource.dart';
import 'package:punto_venta_app/features/pos/data/models/mercado_pago/enterprise_data_model.dart';
import 'package:punto_venta_app/features/pos/data/models/mercado_pago/mp_credentials_model.dart';
import 'package:punto_venta_app/features/pos/data/models/mercado_pago/pos_response_model.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/mercado_pago_repository.dart';

class MercadoPagoRepositoryImpl implements MercadoPagoRepository {
  final MercadoPagoRemoteDataSource remoteDataSource;
  final MercadoPagoLocalDataSource localDataSource;

  MercadoPagoRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<EnterpriseDataModel> fetchEnterpriseData(int enterpriseId) {
    return remoteDataSource.fetchEnterpriseData(enterpriseId);
  }

  @override
  Future<PosResponseModel> createPos({
    required String mpToken,
    required int userId,
    required StoreModel? mpStore,
  }) {
    return remoteDataSource.createPos(
      mpToken: mpToken,
      userId: userId,
      mpStore: mpStore,
    );
  }

  @override
  Future<void> saveExternalPosIdToFirestore({
    required int enterpriseId,
    required int userId,
    required String externalPosId,
  }) {
    return remoteDataSource.saveExternalPosIdToFirestore(
      enterpriseId: enterpriseId,
      userId: userId,
      externalPosId: externalPosId,
    );
  }

  @override
  Future<void> cacheCredentials({
    required String accessToken,
    required String externalPosId,
  }) async {
    await localDataSource.saveAccessToken(accessToken);
    await localDataSource.saveExternalPosId(externalPosId);
  }

  @override
  Future<String?> getCachedAccessToken() => localDataSource.getAccessToken();

  @override
  Future<String?> getCachedExternalPosId() =>
      localDataSource.getExternalPosId();

  @override
  Future<void> clearCachedCredentials() => localDataSource.clear();

  @override
  Future<bool> hasValidCredentials() async {
    final token = await localDataSource.getAccessToken();
    final posId = await localDataSource.getExternalPosId();
    return token != null &&
        token.isNotEmpty &&
        posId != null &&
        posId.isNotEmpty &&
        posId != 'null';
  }
}
