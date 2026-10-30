import 'package:punto_venta_app/features/pos/data/models/mercado_pago/enterprise_data_model.dart';
import 'package:punto_venta_app/features/pos/data/models/mercado_pago/mp_credentials_model.dart';
import 'package:punto_venta_app/features/pos/data/models/mercado_pago/pos_response_model.dart';

abstract class MercadoPagoRepository {
  Future<EnterpriseDataModel> fetchEnterpriseData(int enterpriseId);
  Future<PosResponseModel> createPos({
    required String mpToken,
    required int userId,
    required StoreModel? mpStore,
  });
  Future<void> saveExternalPosIdToFirestore({
    required int enterpriseId,
    required int userId,
    required String externalPosId,
  });
  Future<void> cacheCredentials({
    required String accessToken,
    required String externalPosId,
  });
  Future<String?> getCachedAccessToken();
  Future<String?> getCachedExternalPosId();
  Future<void> clearCachedCredentials();
  Future<bool> hasValidCredentials();
}
