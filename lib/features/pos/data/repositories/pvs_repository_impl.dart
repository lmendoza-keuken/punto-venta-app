import 'package:punto_venta_app/core/services/pvs_service.dart';
import 'package:punto_venta_app/features/pos/data/datasources/mercado_pago_remote_datasource.dart';
import 'package:punto_venta_app/features/pos/data/models/mercado_pago/pvs_credentials_model.dart';
import 'package:punto_venta_app/features/pos/data/models/pvs/pvs_qr_generate_request_model.dart';
import 'package:punto_venta_app/features/pos/data/models/pvs/pvs_qr_generate_response_model.dart';
import 'package:punto_venta_app/features/pos/data/models/pvs/pvs_reverse_response_model.dart';
import 'package:punto_venta_app/features/pos/data/models/pvs/pvs_transaction_status_response_model.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/pvs_repository.dart';

class PvsRepositoryImpl implements PvsRepository {
  final MercadoPagoRemoteDataSource mercadoPagoRemoteDataSource;
  final PvsService pvsService;

  List<PvsCredentials>? _cachedCredentials;
  int? _cachedEnterpriseId;

  PvsRepositoryImpl({
    required this.mercadoPagoRemoteDataSource,
    required this.pvsService,
  });

  @override
  Future<void> bootstrapCredentials(int enterpriseId) async {
    final enterprise =
        await mercadoPagoRemoteDataSource.fetchEnterpriseData(enterpriseId);
    _cachedCredentials =
        List<PvsCredentials>.from(enterprise.pvsCredentials ?? []);
    _cachedEnterpriseId = enterpriseId;
  }

  @override
  Future<PvsCredentials?> resolveCredentials({
    required int enterpriseId,
    required int paymentMethodId,
  }) async {
    if (_cachedCredentials == null || _cachedEnterpriseId != enterpriseId) {
      await bootstrapCredentials(enterpriseId);
    }

    final list = _cachedCredentials;
    if (list == null || list.isEmpty) return null;
    for (final cred in list) {
      if (cred.paymentMethodId == paymentMethodId) return cred;
    }
    return null;
  }

  @override
  Future<void> clearCachedCredentials() async {
    _cachedCredentials = null;
    _cachedEnterpriseId = null;
  }

  @override
  Future<String> obtainAccessToken(PvsCredentials credentials) async {
    final clientId = credentials.clientId ?? '';
    final clientSecret = credentials.clientSecret ?? '';
    if (clientId.isEmpty || clientSecret.isEmpty) {
      throw Exception('Credenciales PVS incompletas (clientId/clientSecret)');
    }
    final token = await pvsService.getAccessToken(
      clientId: clientId,
      clientSecret: clientSecret,
    );
    final accessToken = token.accessToken ?? '';
    if (accessToken.isEmpty) {
      throw Exception('Token PVS vacío en la respuesta');
    }
    return accessToken;
  }

  @override
  Future<PvsQrGenerateData> generateQr({
    required String accessToken,
    required double amount,
    required String externalId,
    required String reference,
  }) async {
    final response = await pvsService.generateQr(
      accessToken: accessToken,
      request: PvsQrGenerateRequest(
        amount: formatPvsAmount(amount),
        externalId: externalId,
        reference: reference,
      ),
    );
    final data = response.data;
    if (data == null ||
        data.qrId == null ||
        data.qrId!.isEmpty ||
        data.qrImage == null ||
        data.qrImage!.isEmpty) {
      throw Exception('Respuesta inválida al generar QR PVS (falta qrImage)');
    }
    return data;
  }

  @override
  Future<PvsTransactionStatusResponse> checkQrStatus({
    required String accessToken,
    required String qrId,
  }) {
    return pvsService.checkQrStatus(accessToken: accessToken, qrId: qrId);
  }

  @override
  Future<PvsReverseResponse> reverseQr({
    required String accessToken,
    required String qrId,
  }) {
    return pvsService.reverseQr(accessToken: accessToken, qrId: qrId);
  }
}
