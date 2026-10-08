import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/mercado_pago_qr/mercado_pago_qr_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/mercado_pago_qr/mercado_pago_qr_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/mercado_pago_qr/mercado_pago_qr_state.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/mercado_pago/payment_approved_view.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/mercado_pago/payment_error_view.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/mercado_pago/payment_loading_view.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/mercado_pago/payment_pending_view.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/mercado_pago/payment_rejected_view.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/mercado_pago/qr_generated_view.dart';

class MercadoPagoQrWidget extends StatelessWidget {
  final double totalAmount;
  final ValueChanged<MpPaymentResult> onApproved;
  final VoidCallback onCancelled;

  const MercadoPagoQrWidget({
    super.key,
    required this.totalAmount,
    required this.onApproved,
    required this.onCancelled,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MercadoPagoQrBloc, MercadoPagoQrState>(
      builder: (context, state) {
        if (state is MercadoPagoQrLoading) {
          return const PaymentLoadingView();
        }
        if (state is MercadoPagoQrGenerated) {
          return QrGeneratedView(
            orderId: state.orderId,
            qrData: state.qrData,
            totalAmount: totalAmount,
            onCancelled: onCancelled,
          );
        }
        if (state is MercadoPagoQrPaymentPending) {
          return const PaymentPendingView();
        }
        if (state is MercadoPagoQrPaymentApproved) {
          return PaymentApprovedView(
            paymentId: state.result.paymentId,
            referenceId: state.result.referenceId,
            isAccountMoney: state.result.isAccountMoney,
            onTap: () => onApproved(state.result),
          );
        }
        if (state is MercadoPagoQrPaymentRejected) {
          return PaymentRejectedView(
            reason: state.reason,
            onClose: onCancelled,
          );
        }
        if (state is MercadoPagoQrExpired) {
          return PaymentErrorView(
            message: 'El código QR expiró. Generá uno nuevo para continuar.',
            onRetry: () {
              context.read<MercadoPagoQrBloc>().add(
                    GenerateMercadoPagoQr(amount: totalAmount),
                  );
            },
            onCancel: onCancelled,
          );
        }
        if (state is MercadoPagoQrError) {
          return PaymentErrorView(
            message: state.message,
            onRetry: () {
              context.read<MercadoPagoQrBloc>().add(
                    GenerateMercadoPagoQr(amount: totalAmount),
                  );
            },
            onCancel: onCancelled,
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
