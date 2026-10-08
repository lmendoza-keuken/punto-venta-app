import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:punto_venta_app/core/services/mercado_pago_service.dart';
import 'package:punto_venta_app/features/pos/data/models/mercado_pago/enterprise_data_model.dart';
import 'package:punto_venta_app/features/pos/data/models/mercado_pago/mp_credentials_model.dart';
import 'package:punto_venta_app/features/pos/data/models/mercado_pago/pos_request_model.dart';
import 'package:punto_venta_app/features/pos/data/models/mercado_pago/pos_response_model.dart';

abstract class MercadoPagoRemoteDataSource {
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
}

class MercadoPagoRemoteDataSourceImpl implements MercadoPagoRemoteDataSource {
  final FirebaseFirestore firestore;
  final MercadoPagoService mercadoPagoService;

  MercadoPagoRemoteDataSourceImpl({
    required this.firestore,
    required this.mercadoPagoService,
  });

  @override
  Future<EnterpriseDataModel> fetchEnterpriseData(int enterpriseId) async {
    final snapshot =
        await firestore.doc('/distribution/$enterpriseId').get();
    if (!snapshot.exists || snapshot.data() == null) {
      throw Exception('No se encontró la empresa en Firestore');
    }
    return EnterpriseDataModel.fromJson(snapshot.data()!);
  }

  @override
  Future<PosResponseModel> createPos({
    required String mpToken,
    required int userId,
    required StoreModel? mpStore,
  }) async {
    if (mpStore == null ||
        mpStore.storeId == null ||
        mpStore.mpExternalStoreId == null) {
      throw Exception('No hay información de tienda configurada');
    }

    mercadoPagoService.setAccessToken(mpToken);

    final externalPosId = 'SUC${mpStore.storeId}POS$userId';
    final posName = 'Caja Usuario $userId';

    final posRequest = PosRequestModel(
      category: 621102,
      externalId: externalPosId,
      externalStoreId: mpStore.mpExternalStoreId!,
      fixedAmount: true,
      name: posName,
      storeId: int.tryParse(mpStore.storeId ?? '')!,
    );

    return mercadoPagoService.createPos(posRequest: posRequest);
  }

  @override
  Future<void> saveExternalPosIdToFirestore({
    required int enterpriseId,
    required int userId,
    required String externalPosId,
  }) async {
    final docRef = firestore.doc('/distribution/$enterpriseId');
    await docRef.update({
      'mpCredentials.mpExternalPosIds': FieldValue.arrayUnion([
        {
          'mpExternalPosId': externalPosId,
          'userId': userId,
        }
      ])
    });
  }
}
