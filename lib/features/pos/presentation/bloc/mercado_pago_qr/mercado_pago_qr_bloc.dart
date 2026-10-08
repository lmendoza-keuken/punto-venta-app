import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:punto_venta_app/core/services/mercado_pago_service.dart';
import 'package:punto_venta_app/features/auth/data/datasources/auth_local_datasources.dart';
import 'package:punto_venta_app/features/pos/data/models/mercado_pago/config_qr_request_model.dart';
import 'package:punto_venta_app/features/pos/data/models/mercado_pago/mercado_pago_qr_request_model.dart';
import 'package:punto_venta_app/features/pos/data/models/mercado_pago/transactions_qr_request_model.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/mercado_pago_repository.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/pdv_config_repository.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/mercado_pago_qr/mercado_pago_qr_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/mercado_pago_qr/mercado_pago_qr_state.dart';

class MercadoPagoQrBloc extends Bloc<MercadoPagoQrEvent, MercadoPagoQrState> {
  final MercadoPagoService mercadoPagoService;
  final MercadoPagoRepository mercadoPagoRepository;
  final AuthLocalDataSource authLocalDataSource;
  final PdvConfigRepository pdvConfigRepository;

  Timer? _pollingTimer;
  Timer? _expirationTimer;
  String? _currentOrderId;

  static const _pollInterval = Duration(seconds: 3);
  static const _expiration = Duration(minutes: 16);

  MercadoPagoQrBloc({
    required this.mercadoPagoService,
    required this.mercadoPagoRepository,
    required this.authLocalDataSource,
    required this.pdvConfigRepository,
  }) : super(const MercadoPagoQrInitial()) {
    on<GenerateMercadoPagoQr>(_onGenerate);
    on<CheckMercadoPagoStatus>(_onCheckStatus);
    on<CancelMercadoPagoOrder>(_onCancel);
    on<ResetMercadoPagoQr>(_onReset);
    on<ExpireMercadoPagoQr>(_onExpire);
  }

  Future<void> _onGenerate(
    GenerateMercadoPagoQr event,
    Emitter<MercadoPagoQrState> emit,
  ) async {
    emit(const MercadoPagoQrLoading());
    _stopTimers();

    try {
      final mpToken = await mercadoPagoRepository.getCachedAccessToken();
      final externalPosId =
          await mercadoPagoRepository.getCachedExternalPosId();

      if (mpToken == null ||
          mpToken.isEmpty ||
          externalPosId == null ||
          externalPosId.isEmpty) {
        emit(const MercadoPagoQrError(
          message: 'Credenciales de Mercado Pago no configuradas',
        ));
        return;
      }

      mercadoPagoService.setAccessToken(mpToken);

      final enterprise = await authLocalDataSource.getCachedEnterprise();
      final user = await authLocalDataSource.getCachedUser();
      final pdvConfig = await pdvConfigRepository.getLocalPdvConfig();
      final pdvId = pdvConfig?.pdvId ?? 0;
      final userId = user?.id ?? '0';
      final enterpriseName = enterprise?.name ?? '';

      final now = DateTime.now();
      final formattedDate = DateFormat('yyyyMMddHHmm').format(now);
      final externalReference = event.externalReference ??
          'PDV$pdvId-$userId-$formattedDate';

      final response = await mercadoPagoService.generateQrOrder(
        qrRequest: MercadoPagoQrRequest(
          type: 'qr',
          expirationTime: 'PT16M',
          description: event.description ?? 'Pago a $enterpriseName',
          externalReference: externalReference,
          // totalAmount: event.amount.toStringAsFixed(2),
          totalAmount: '15.00',
          transactions: const TransactionsQrRequest(
            payments: [
              PaymentsQrRequest(
                amount: '15.00',
                // amount: event.amount.toStringAsFixed(2),
              ),
            ],
          ),
          config: ConfigQrRequest(
            qr: QrConfig(
              externalPosId: externalPosId,
              mode: 'dynamic',
            ),
          ),
        ),
      );

      final orderId = response.id ?? '';
      final qrData = response.typeResponse?.qrData ?? '';
      if (orderId.isEmpty || qrData.isEmpty) {
        emit(const MercadoPagoQrError(
          message: 'Respuesta inválida al generar QR',
        ));
        return;
      }

      _currentOrderId = orderId;
      emit(MercadoPagoQrGenerated(qrData: qrData, orderId: orderId));
      _startStatusPolling(orderId);
      _startExpirationTimer(orderId);
    } catch (e) {
      emit(MercadoPagoQrError(message: e.toString()));
    }
  }

  Future<void> _onCheckStatus(
    CheckMercadoPagoStatus event,
    Emitter<MercadoPagoQrState> emit,
  ) async {
    try {
      final status =
          await mercadoPagoService.checkQrOrderStatus(orderId: event.orderId);
      final orderStatus = status.status;
      final payment = status.transactions?.payments?.firstOrNull;
      final isNotAccountMoney =
          payment?.paymentMethod?.type != null &&
              payment?.paymentMethod?.type != 'account_money';

      switch (orderStatus) {
        case 'processed':
          _stopTimers();
          emit(MercadoPagoQrPaymentApproved(
            result: MpPaymentResult(
              orderId: event.orderId,
              paymentId: payment?.id?.toString() ?? '',
              referenceId: payment?.referenceId?.toString() ?? '',
              paymentType: payment?.paymentMethod?.type ?? '',
              paymentDate: status.lastUpdatedDate?.toString() ?? '',
              isAccountMoney: !isNotAccountMoney,
            ),
          ));
          break;
        case 'payment_in_process':
          emit(const MercadoPagoQrPaymentPending());
          break;
        case 'cancelled':
        case 'canceled':
          _stopTimers();
          emit(const MercadoPagoQrPaymentRejected(
            reason: 'La orden fue cancelada',
          ));
          break;
        case 'expired':
          _stopTimers();
          emit(const MercadoPagoQrExpired());
          break;
        case 'action_required':
        case 'failed':
        case 'rejected':
          _stopTimers();
          emit(MercadoPagoQrPaymentRejected(
            reason: status.statusDetail ?? orderStatus ?? 'Pago rechazado',
          ));
          break;
        default:
          break;
      }
    } catch (_) {
      // Keep showing QR on transient poll errors.
    }
  }

  Future<void> _onCancel(
    CancelMercadoPagoOrder event,
    Emitter<MercadoPagoQrState> emit,
  ) async {
    _stopTimers();
    try {
      await mercadoPagoService.cancelQrOrder(orderId: event.orderId);
      emit(const MercadoPagoQrInitial());
    } catch (e) {
      emit(MercadoPagoQrError(message: e.toString()));
    }
  }

  void _onReset(
    ResetMercadoPagoQr event,
    Emitter<MercadoPagoQrState> emit,
  ) {
    _stopTimers();
    _currentOrderId = null;
    emit(const MercadoPagoQrInitial());
  }

  void _onExpire(
    ExpireMercadoPagoQr event,
    Emitter<MercadoPagoQrState> emit,
  ) {
    _stopTimers();
    emit(const MercadoPagoQrExpired());
  }

  void _startStatusPolling(String orderId) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(_pollInterval, (_) {
      if (!isClosed) {
        add(CheckMercadoPagoStatus(orderId: orderId));
      }
    });
  }

  void _startExpirationTimer(String orderId) {
    _expirationTimer?.cancel();
    _expirationTimer = Timer(_expiration, () {
      if (!isClosed && _currentOrderId == orderId) {
        add(const ExpireMercadoPagoQr());
      }
    });
  }

  void _stopTimers() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _expirationTimer?.cancel();
    _expirationTimer = null;
  }

  @override
  Future<void> close() {
    _stopTimers();
    return super.close();
  }
}
