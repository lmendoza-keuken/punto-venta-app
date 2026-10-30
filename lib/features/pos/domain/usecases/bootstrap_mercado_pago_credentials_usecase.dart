import 'package:punto_venta_app/features/pos/data/models/mercado_pago/external_pos_bootstrap_result.dart';
import 'package:punto_venta_app/features/pos/data/models/mercado_pago/mp_credentials_model.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/mercado_pago_repository.dart';

class BootstrapMercadoPagoCredentialsUsecase {
  final MercadoPagoRepository repository;

  BootstrapMercadoPagoCredentialsUsecase(this.repository);

  /// Returns [needsCreatePos] when token exists but the cashier has no caja.
  Future<MpBootstrapResult> call({
    required int enterpriseId,
    required int userId,
    bool createPosIfMissing = false,
  }) async {
    final enterprise = await repository.fetchEnterpriseData(enterpriseId);
    final credentials = enterprise.mpCredentials;
    final mpToken = credentials?.mpAccessToken ?? '';

    if (mpToken.isEmpty) {
      await repository.clearCachedCredentials();
      return const MpBootstrapResult(hasToken: false);
    }

    final userPos = credentials?.mpExternalPosIds?.firstWhere(
      (posId) => posId.userId == userId,
      orElse: () => ExternalPosIdModel(mpExternalPosId: null, userId: null),
    );
    var mpExternalPosId = userPos?.mpExternalPosId;

    if (mpExternalPosId == null || mpExternalPosId.isEmpty) {
      if (!createPosIfMissing) {
        return MpBootstrapResult(
          hasToken: true,
          needsCreatePos: true,
          mpStore: credentials?.mpStore,
          accessToken: mpToken,
        );
      }

      final posResponse = await repository.createPos(
        mpToken: mpToken,
        userId: userId,
        mpStore: credentials?.mpStore,
      );
      final newExternalPosId = posResponse.externalId ?? '';
      if (newExternalPosId.isEmpty) {
        throw Exception('No se pudo obtener el externalPosId de la respuesta');
      }
      await repository.saveExternalPosIdToFirestore(
        enterpriseId: enterpriseId,
        userId: userId,
        externalPosId: newExternalPosId,
      );
      mpExternalPosId = newExternalPosId;
    }

    await repository.cacheCredentials(
      accessToken: mpToken,
      externalPosId: mpExternalPosId,
    );

    return MpBootstrapResult(
      hasToken: true,
      needsCreatePos: false,
      accessToken: mpToken,
      externalPosId: mpExternalPosId,
      mpStore: credentials?.mpStore,
      createdPos: createPosIfMissing,
    );
  }
}
