import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:punto_venta_app/features/auth/data/datasources/auth_local_datasources.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/pdv_config_repository.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/pvs_repository.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/pvs_qr/pvs_qr_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/pvs_qr/pvs_qr_state.dart';
import 'package:punto_venta_app/features/pos/presentation/utils/pvs_qr_mock.dart';

class PvsQrBloc extends Bloc<PvsQrEvent, PvsQrState> {
  final PvsRepository pvsRepository;
  final AuthLocalDataSource authLocalDataSource;
  final PdvConfigRepository pdvConfigRepository;

  Timer? _pollingTimer;
  Timer? _countdownTimer;
  String? _accessToken;
  String? _qrImageBase64;
  String? _qrRaw;
  String? _lastQrId;
  DateTime? _expiresAt;
  double? _lastAmount;
  int? _lastPaymentMethodId;
  String? _lastDescription;
  String? _lastExternalId;
  bool _simulatingPayment = false;

  static const _pollInterval = Duration(seconds: 3);
  static const _defaultExpirationSeconds = 180;

  PvsQrBloc({
    required this.pvsRepository,
    required this.authLocalDataSource,
    required this.pdvConfigRepository,
  }) : super(const PvsQrInitial()) {
    on<GeneratePvsQr>(_onGenerate);
    on<CheckPvsStatus>(_onCheckStatus);
    on<CancelPvsQrSession>(_onCancelSession);
    on<ResetPvsQr>(_onReset);
    on<ExpirePvsQr>(_onExpire);
    on<TickPvsQrCountdown>(_onTickCountdown);
    on<SimulatePvsHomoPayment>(_onSimulateHomoPayment);
  }

  Future<void> _onGenerate(
    GeneratePvsQr event,
    Emitter<PvsQrState> emit,
  ) async {
    emit(const PvsQrLoading());
    _stopTimers();

    _lastAmount = event.amount;
    _lastPaymentMethodId = event.paymentMethodId;
    _lastDescription = event.description;
    _lastExternalId = event.externalId;

    try {
      final enterprise = await authLocalDataSource.getCachedEnterprise();
      final enterpriseId = enterprise?.id;
      if (enterpriseId == null) {
        emit(const PvsQrError(message: 'Empresa no configurada'));
        return;
      }

      final credentials = await pvsRepository.resolveCredentials(
        enterpriseId: enterpriseId,
        paymentMethodId: event.paymentMethodId,
      );
      if (credentials == null) {
        emit(const PvsQrError(
          message: 'No hay credenciales PVS para este método de pago',
        ));
        return;
      }

      final accessToken = await pvsRepository.obtainAccessToken(credentials);
      _accessToken = accessToken;

      final user = await authLocalDataSource.getCachedUser();
      final pdvConfig = await pdvConfigRepository.getLocalPdvConfig();
      final pdvId = pdvConfig?.pdvId ?? 0;
      final userId = user?.id ?? '0';
      final enterpriseName = enterprise?.name ?? '';

      final now = DateTime.now();
      final formattedDate = DateFormat('yyyyMMddHHmm').format(now);
      final externalId =
          event.externalId ?? 'PDV$pdvId-$userId-$formattedDate';
      final reference =
          event.description ?? 'Pago a $enterpriseName';

      final data = await pvsRepository.generateQr(
        accessToken: accessToken,
        amount: event.amount,
        externalId: externalId,
        reference: reference,
      );

      final qrId = data.qrId!;
      final qrRaw = data.qrRaw;
      final qrImage = data.qrImage;
      final expirationSeconds = data.expiration ?? _defaultExpirationSeconds;

      _qrRaw = qrRaw;
      _qrImageBase64 = qrImage;
      _lastQrId = qrId;
      _expiresAt = DateTime.now().add(Duration(seconds: expirationSeconds));

      emit(PvsQrGenerated(
        qrId: qrId,
        qrRaw: qrRaw,
        qrImageBase64: qrImage,
        secondsRemaining: expirationSeconds,
      ));
      _startStatusPolling(qrId);
      _startCountdownTimer();
    } catch (e) {
      emit(PvsQrError(message: _cleanError(e)));
    }
  }

  Future<void> _onSimulateHomoPayment(
    SimulatePvsHomoPayment event,
    Emitter<PvsQrState> emit,
  ) async {
    if (!kPvsQrMockEnabled || _simulatingPayment) return;

    final qrRaw = _qrRaw;
    final qrId = _lastQrId;
    if (qrRaw == null || qrRaw.isEmpty) {
      emit(const PvsQrError(
        message: 'No hay qrRaw para simular el pago',
      ));
      return;
    }

    _simulatingPayment = true;
    try {
      final current = state;
      if (current is PvsQrGenerated) {
        emit(PvsQrPaymentPending(
          qrId: current.qrId,
          qrRaw: current.qrRaw,
          qrImageBase64: current.qrImageBase64,
          secondsRemaining: current.secondsRemaining,
        ));
      }

      await pvsRepository.simulateHomoPayment(qrRaw: qrRaw);
      if (qrId != null && qrId.isNotEmpty) {
        add(CheckPvsStatus(qrId: qrId));
      }
    } catch (_) {
      // Mantener el QR visible; el error queda en el LogInterceptor de Dio.
    } finally {
      _simulatingPayment = false;
    }
  }

  Future<void> _onCheckStatus(
    CheckPvsStatus event,
    Emitter<PvsQrState> emit,
  ) async {
    final token = _accessToken;
    if (token == null || token.isEmpty) return;

    try {
      final status = await pvsRepository.checkQrStatus(
        accessToken: token,
        qrId: event.qrId,
      );
      final data = status.data;
      final stateId = data?.stateId;
      final secondsRemaining = _secondsRemaining();

      switch (stateId) {
        case 5: // Approved
          _stopTimers();
          emit(PvsQrPaymentApproved(
            result: PvsPaymentResult(
              orderId: data?.qrId ?? event.qrId,
              paymentId: data?.id ?? '',
              paymentDate: data?.createdAt ?? '',
              paymentStatus: data?.paymentStatus ?? data?.state ?? 'APPROVED',
              wallet: data?.wallet ?? '',
            ),
          ));
          break;
        case 6: // Processing
          emit(PvsQrPaymentPending(
            qrId: event.qrId,
            qrRaw: _qrRaw,
            qrImageBase64: _qrImageBase64,
            secondsRemaining: secondsRemaining,
          ));
          break;
        case 3: // Rejected
          _stopTimers();
          emit(PvsQrPaymentRejected(
            reason: data?.state ?? data?.paymentStatus ?? 'Pago rechazado',
          ));
          break;
        case 4: // Reversed
          _stopTimers();
          emit(const PvsQrPaymentRejected(
            reason: 'La transacción fue revertida',
          ));
          break;
        default:
          break;
      }
    } catch (e) {
      // Transient poll errors: keep QR. Log so parse bugs aren't silent.
      assert(() {
        // ignore: avoid_print
        print('[PVS] check status failed: $e');
        return true;
      }());
    }
  }

  void _onCancelSession(
    CancelPvsQrSession event,
    Emitter<PvsQrState> emit,
  ) {
    _stopTimers();
    _accessToken = null;
    _qrImageBase64 = null;
    _qrRaw = null;
    _lastQrId = null;
    _expiresAt = null;
    emit(const PvsQrInitial());
  }

  void _onReset(
    ResetPvsQr event,
    Emitter<PvsQrState> emit,
  ) {
    _stopTimers();
    _accessToken = null;
    _qrImageBase64 = null;
    _qrRaw = null;
    _lastQrId = null;
    _expiresAt = null;
    emit(const PvsQrInitial());
  }

  void _onExpire(
    ExpirePvsQr event,
    Emitter<PvsQrState> emit,
  ) {
    _stopTimers();
    emit(const PvsQrExpired());
  }

  void _onTickCountdown(
    TickPvsQrCountdown event,
    Emitter<PvsQrState> emit,
  ) {
    final remaining = _secondsRemaining();
    if (remaining <= 0) {
      add(const ExpirePvsQr());
      return;
    }

    final current = state;
    if (current is PvsQrGenerated) {
      emit(PvsQrGenerated(
        qrId: current.qrId,
        qrRaw: current.qrRaw,
        qrImageBase64: current.qrImageBase64,
        secondsRemaining: remaining,
      ));
    } else if (current is PvsQrPaymentPending) {
      emit(PvsQrPaymentPending(
        qrId: current.qrId,
        qrRaw: current.qrRaw,
        qrImageBase64: current.qrImageBase64,
        secondsRemaining: remaining,
      ));
    }
  }

  void regenerate() {
    final amount = _lastAmount;
    final paymentMethodId = _lastPaymentMethodId;
    if (amount == null || paymentMethodId == null) return;
    add(GeneratePvsQr(
      amount: amount,
      paymentMethodId: paymentMethodId,
      description: _lastDescription,
      externalId: _lastExternalId,
    ));
  }

  int _secondsRemaining() {
    final expiresAt = _expiresAt;
    if (expiresAt == null) return 0;
    final diff = expiresAt.difference(DateTime.now()).inSeconds;
    return diff < 0 ? 0 : diff;
  }

  void _startStatusPolling(String qrId) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(_pollInterval, (_) {
      if (!isClosed) {
        add(CheckPvsStatus(qrId: qrId));
      }
    });
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isClosed) {
        add(const TickPvsQrCountdown());
      }
    });
  }

  void _stopTimers() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  String _cleanError(Object e) {
    var message = e.toString();
    while (message.startsWith('Exception: ')) {
      message = message.replaceFirst('Exception: ', '');
    }
    return message;
  }

  @override
  Future<void> close() {
    _stopTimers();
    return super.close();
  }
}
