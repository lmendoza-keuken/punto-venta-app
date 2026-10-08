import 'package:punto_venta_app/features/pos/data/models/mercado_pago/pvs_credentials_model.dart';
import 'package:punto_venta_app/features/pos/data/models/pvs/pvs_qr_generate_response_model.dart';
import 'package:punto_venta_app/features/pos/data/models/pvs/pvs_reverse_response_model.dart';
import 'package:punto_venta_app/features/pos/data/models/pvs/pvs_transaction_status_response_model.dart';

abstract class PvsRepository {
  /// Lee `pvsCredentials` de Firestore una vez y las deja en memoria.
  Future<void> bootstrapCredentials(int enterpriseId);

  Future<PvsCredentials?> resolveCredentials({
    required int enterpriseId,
    required int paymentMethodId,
  });

  Future<void> clearCachedCredentials();

  Future<String> obtainAccessToken(PvsCredentials credentials);

  Future<PvsQrGenerateData> generateQr({
    required String accessToken,
    required double amount,
    required String externalId,
    required String reference,
  });

  Future<PvsTransactionStatusResponse> checkQrStatus({
    required String accessToken,
    required String qrId,
  });

  Future<PvsReverseResponse> reverseQr({
    required String accessToken,
    required String qrId,
  });
}
