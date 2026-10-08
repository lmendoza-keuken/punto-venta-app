import 'package:punto_venta_app/features/pos/data/models/mercado_pago/mp_credentials_model.dart';

class MpBootstrapResult {
  final bool hasToken;
  final bool needsCreatePos;
  final bool createdPos;
  final String? accessToken;
  final String? externalPosId;
  final StoreModel? mpStore;

  const MpBootstrapResult({
    required this.hasToken,
    this.needsCreatePos = false,
    this.createdPos = false,
    this.accessToken,
    this.externalPosId,
    this.mpStore,
  });
}
