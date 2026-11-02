import 'package:punto_venta_app/features/customer_display/domain/customer_display_qr.dart';
import 'package:punto_venta_app/features/customer_display/domain/customer_display_service.dart';
import 'package:punto_venta_app/features/customer_display/domain/customer_display_snapshot.dart';
import 'package:punto_venta_app/features/pos/domain/entities/payment_method.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_state.dart';
import 'package:punto_venta_app/injection_container.dart' as di;

/// Memoria corta del QR activo para que el binder no lo pise durante el polling.
class CustomerDisplayQrBridge {
  CustomerDisplayQrBridge._();

  static String? label;
  static String? payload;
  static String? detail;
  static CustomerDisplayQrPhase phase = CustomerDisplayQrPhase.none;

  static void set({
    required String label,
    String? payload,
    String? detail,
    CustomerDisplayQrPhase phase = CustomerDisplayQrPhase.ready,
  }) {
    CustomerDisplayQrBridge.label = label;
    CustomerDisplayQrBridge.payload = payload;
    CustomerDisplayQrBridge.detail = detail;
    CustomerDisplayQrBridge.phase = phase;
  }

  static void clear() {
    label = null;
    payload = null;
    detail = null;
    phase = CustomerDisplayQrPhase.none;
  }

  static bool get hasQr =>
      payload != null && payload!.trim().isNotEmpty;

  static bool get hasActivePhase =>
      phase != CustomerDisplayQrPhase.none;
}

/// Empuja estado de pago (con QR si aplica) a la pantalla cliente.
Future<void> syncCustomerDisplayPayment({
  required CartLoaded cart,
  required List<PaymentMethod> selectedPayments,
  bool isProcessing = false,
  String? qrLabel,
  String? qrPayload,
  bool clearQr = false,
}) async {
  final service = di.sl<CustomerDisplayService>();
  if (!service.isEnabled) return;

  if (clearQr) {
    CustomerDisplayQrBridge.clear();
  }

  final qrPayment = findCustomerDisplayQrPayment(selectedPayments);
  final resolvedLabel = clearQr
      ? null
      : (qrLabel ??
          CustomerDisplayQrBridge.label ??
          (qrPayment != null ? customerDisplayQrLabel(qrPayment) : null));
  final resolvedPayload = clearQr
      ? null
      : (qrPayload ?? CustomerDisplayQrBridge.payload);

  if (!clearQr &&
      resolvedLabel != null &&
      resolvedPayload != null &&
      resolvedPayload.trim().isNotEmpty) {
    CustomerDisplayQrBridge.set(
      label: resolvedLabel,
      payload: resolvedPayload,
      detail: CustomerDisplayQrBridge.detail,
      phase: CustomerDisplayQrBridge.phase == CustomerDisplayQrPhase.none
          ? CustomerDisplayQrPhase.ready
          : CustomerDisplayQrBridge.phase,
    );
  }

  final snapshot = CustomerDisplaySnapshot.fromCartLoaded(
    cart,
    mode: CustomerDisplayMode.payment,
    qrLabel: resolvedLabel,
    qrPayload: resolvedPayload,
    qrPhase: clearQr
        ? CustomerDisplayQrPhase.none
        : CustomerDisplayQrBridge.phase,
    qrDetail: clearQr ? null : CustomerDisplayQrBridge.detail,
    isProcessing: isProcessing,
  );
  await service.sync(snapshot);
}

/// Sync inmediato cuando el POS genera / regenera el QR (MP o PVS).
Future<void> syncCustomerDisplayQr({
  required CartLoaded cart,
  required String label,
  required String payload,
  CustomerDisplayQrPhase phase = CustomerDisplayQrPhase.ready,
}) async {
  final service = di.sl<CustomerDisplayService>();
  if (!service.isEnabled) return;
  if (payload.trim().isEmpty) return;

  CustomerDisplayQrBridge.set(
    label: label,
    payload: payload,
    phase: phase,
  );

  final snapshot = CustomerDisplaySnapshot.fromCartLoaded(
    cart,
    mode: CustomerDisplayMode.payment,
    qrLabel: label,
    qrPayload: payload,
    qrPhase: phase,
  );
  await service.sync(snapshot);
}

/// Sync de fase del cobro QR (mismo switch que el confirmation panel).
///
/// En approved/rejected/expired se limpia el payload para cambiar de vista.
Future<void> syncCustomerDisplayQrPhase({
  required CartLoaded cart,
  required String label,
  required CustomerDisplayQrPhase phase,
  String? payload,
  String? detail,
  /// MP pending oculta el QR; PVS pending lo mantiene.
  bool clearPayload = false,
}) async {
  final service = di.sl<CustomerDisplayService>();
  if (!service.isEnabled) return;

  final keepPayload = !clearPayload &&
      (phase == CustomerDisplayQrPhase.ready ||
          phase == CustomerDisplayQrPhase.pending);
  final resolvedPayload =
      keepPayload ? (payload ?? CustomerDisplayQrBridge.payload) : null;

  CustomerDisplayQrBridge.set(
    label: label,
    payload: resolvedPayload,
    detail: detail,
    phase: phase,
  );

  final snapshot = CustomerDisplaySnapshot.fromCartLoaded(
    cart,
    mode: CustomerDisplayMode.payment,
    qrLabel: label,
    qrPayload: resolvedPayload,
    qrPhase: phase,
    qrDetail: detail,
  );
  await service.sync(snapshot);
}

/// Quita el QR de la vista cliente (cancelar / salir del paso QR).
Future<void> clearCustomerDisplayQr({
  required CartLoaded cart,
}) async {
  final service = di.sl<CustomerDisplayService>();
  if (!service.isEnabled) return;

  CustomerDisplayQrBridge.clear();

  final snapshot = CustomerDisplaySnapshot.fromCartLoaded(
    cart,
    mode: cart.items.isEmpty
        ? CustomerDisplayMode.idle
        : CustomerDisplayMode.payment,
  );
  await service.sync(snapshot);
}
