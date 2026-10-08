import 'package:punto_venta_app/core/services/mercado_pago_service.dart';
import 'package:punto_venta_app/features/pos/data/models/mercado_pago/associate_qr_refund_request_model.dart';
import 'package:punto_venta_app/features/pos/domain/entities/completed_order.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/mercado_pago_repository.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/pvs_repository.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/returns_repository.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/generate_credit_note_usecase.dart';

/// Fallo al reembolsar en Mercado Pago o PVS (antes de crear la NC).
class MpRefundFailedException implements Exception {
  final String message;

  const MpRefundFailedException(this.message);

  @override
  String toString() => message;
}

class AnnulTicketUsecase {
  final GenerateCreditNoteUsecase generateCreditNoteUsecase;
  final MercadoPagoService mercadoPagoService;
  final MercadoPagoRepository mercadoPagoRepository;
  final PvsRepository pvsRepository;
  final ReturnsRepository returnsRepository;

  AnnulTicketUsecase({
    required this.generateCreditNoteUsecase,
    required this.mercadoPagoService,
    required this.mercadoPagoRepository,
    required this.pvsRepository,
    required this.returnsRepository,
  });

  Future<CompletedOrder?> call({
    required String ticketId,
    required int reasonId,
    required bool refundToMercadoPagoAccount,
    bool refundToPvsAccount = false,
    bool refundInCash = false,
    String? qrOrderId,
    int? pvsPaymentMethodId,
    int? enterpriseId,
  }) async {
    String? qrRefundId;

    if (refundToMercadoPagoAccount) {
      if (qrOrderId == null || qrOrderId.isEmpty) {
        throw const MpRefundFailedException(
          'El ticket no tiene order_id de Mercado Pago asociado',
        );
      }

      try {
        final token = await mercadoPagoRepository.getCachedAccessToken();
        if (token == null || token.isEmpty) {
          throw const MpRefundFailedException(
            'Token de Mercado Pago no configurado',
          );
        }
        mercadoPagoService.setAccessToken(token);

        final refundResponse =
            await mercadoPagoService.refundQrOrder(orderId: qrOrderId);
        qrRefundId = refundResponse.transactions?.refunds?.firstOrNull?.id;
        if (qrRefundId == null || qrRefundId.isEmpty) {
          throw const MpRefundFailedException(
            'No se obtuvo el id de reembolso de Mercado Pago',
          );
        }
      } on MpRefundFailedException {
        rethrow;
      } catch (e) {
        throw MpRefundFailedException(_cleanError(e));
      }
    }

    if (refundToPvsAccount) {
      if (qrOrderId == null || qrOrderId.isEmpty) {
        throw const MpRefundFailedException(
          'El ticket no tiene order_id de PVS asociado',
        );
      }
      if (pvsPaymentMethodId == null || enterpriseId == null) {
        throw const MpRefundFailedException(
          'Faltan datos para reembolsar en PVS (método de pago / empresa)',
        );
      }

      try {
        final credentials = await pvsRepository.resolveCredentials(
          enterpriseId: enterpriseId,
          paymentMethodId: pvsPaymentMethodId,
        );
        if (credentials == null) {
          throw const MpRefundFailedException(
            'No hay credenciales PVS para este método de pago',
          );
        }
        final token = await pvsRepository.obtainAccessToken(credentials);
        final reverse = await pvsRepository.reverseQr(
          accessToken: token,
          qrId: qrOrderId,
        );
        qrRefundId = reverse.qrId ?? qrOrderId;
      } on MpRefundFailedException {
        rethrow;
      } catch (e) {
        throw MpRefundFailedException(_cleanError(e));
      }
    }

    final nc = await generateCreditNoteUsecase(ticketId, reasonId);

    final shouldAssociateQr = nc != null &&
        (refundToMercadoPagoAccount || refundToPvsAccount || refundInCash);
    if (shouldAssociateQr) {
      final ncSaleId = int.tryParse(nc.id);
      if (ncSaleId == null) {
        throw Exception('ID de nota de crédito inválido: ${nc.id}');
      }
      await returnsRepository.associateQrRefund(
        AssociateQrRefundRequest(
          ncSaleId: ncSaleId,
          refundId: (refundToMercadoPagoAccount || refundToPvsAccount)
              ? qrRefundId
              : null,
          inCash: refundInCash,
        ),
      );
    }

    return nc;
  }

  String _cleanError(Object e) {
    var message = e.toString();
    while (message.startsWith('Exception: ')) {
      message = message.replaceFirst('Exception: ', '');
    }
    return message;
  }
}
