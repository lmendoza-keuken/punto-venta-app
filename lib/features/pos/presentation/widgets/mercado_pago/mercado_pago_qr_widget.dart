import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/features/customer_display/domain/customer_display_snapshot.dart';
import 'package:punto_venta_app/features/customer_display/presentation/customer_display_sync.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_state.dart';
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

  CartLoaded? _cart(BuildContext context) {
    final state = context.read<CartBloc>().state;
    return state is CartLoaded ? state : null;
  }

  void _syncPhase(
    BuildContext context,
    CustomerDisplayQrPhase phase, {
    String? payload,
    String? detail,
    bool clearPayload = false,
  }) {
    final cart = _cart(context);
    if (cart == null) return;
    unawaited(syncCustomerDisplayQrPhase(
      cart: cart,
      label: 'Mercado Pago',
      phase: phase,
      payload: payload,
      detail: detail,
      clearPayload: clearPayload,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MercadoPagoQrBloc, MercadoPagoQrState>(
      listenWhen: (previous, current) =>
          previous.runtimeType != current.runtimeType ||
          (current is MercadoPagoQrGenerated &&
              previous is MercadoPagoQrGenerated &&
              previous.qrData != current.qrData),
      listener: (context, state) {
        if (state is MercadoPagoQrGenerated) {
          final cart = _cart(context);
          if (cart == null) return;
          unawaited(syncCustomerDisplayQr(
            cart: cart,
            label: 'Mercado Pago',
            payload: state.qrData,
            phase: CustomerDisplayQrPhase.ready,
          ));
        } else if (state is MercadoPagoQrPaymentPending) {
          // Igual que confirmation panel: pending sin QR.
          _syncPhase(
            context,
            CustomerDisplayQrPhase.pending,
            clearPayload: true,
          );
        } else if (state is MercadoPagoQrPaymentApproved) {
          final id = state.result.paymentId;
          _syncPhase(
            context,
            CustomerDisplayQrPhase.approved,
            detail: id.isNotEmpty ? 'ID: $id' : null,
          );
        } else if (state is MercadoPagoQrPaymentRejected) {
          _syncPhase(
            context,
            CustomerDisplayQrPhase.rejected,
            detail: state.reason,
          );
        } else if (state is MercadoPagoQrExpired) {
          _syncPhase(context, CustomerDisplayQrPhase.expired);
        }
      },
      child: BlocBuilder<MercadoPagoQrBloc, MercadoPagoQrState>(
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
      ),
    );
  }
}
