import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/features/customer_display/domain/customer_display_snapshot.dart';
import 'package:punto_venta_app/features/customer_display/presentation/customer_display_sync.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_state.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/pvs_qr/pvs_qr_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/pvs_qr/pvs_qr_state.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/pvs/pvs_payment_status_view.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/pvs/pvs_qr_generated_view.dart';

class PvsQrWidget extends StatelessWidget {
  final double totalAmount;
  final ValueChanged<PvsPaymentResult> onApproved;
  final VoidCallback onCancelled;

  const PvsQrWidget({
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
  }) {
    final cart = _cart(context);
    if (cart == null) return;
    unawaited(syncCustomerDisplayQrPhase(
      cart: cart,
      label: 'PVS',
      phase: phase,
      payload: payload,
      detail: detail,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PvsQrBloc, PvsQrState>(
      listenWhen: (previous, current) {
        if (previous.runtimeType != current.runtimeType) return true;
        if (current is PvsQrGenerated && previous is PvsQrGenerated) {
          return current.qrRaw != previous.qrRaw;
        }
        if (current is PvsQrPaymentPending &&
            previous is PvsQrPaymentPending) {
          return current.qrRaw != previous.qrRaw;
        }
        return false;
      },
      listener: (context, state) {
        if (state is PvsQrGenerated) {
          final raw = state.qrRaw;
          if (raw == null || raw.trim().isEmpty) return;
          final cart = _cart(context);
          if (cart == null) return;
          unawaited(syncCustomerDisplayQr(
            cart: cart,
            label: 'PVS',
            payload: raw,
            phase: CustomerDisplayQrPhase.ready,
          ));
        } else if (state is PvsQrPaymentPending) {
          _syncPhase(
            context,
            CustomerDisplayQrPhase.pending,
            payload: state.qrRaw,
          );
        } else if (state is PvsQrPaymentApproved) {
          final id = state.result.paymentId;
          _syncPhase(
            context,
            CustomerDisplayQrPhase.approved,
            detail: id.isNotEmpty ? 'ID: $id' : null,
          );
        } else if (state is PvsQrPaymentRejected) {
          _syncPhase(
            context,
            CustomerDisplayQrPhase.rejected,
            detail: state.reason,
          );
        } else if (state is PvsQrExpired) {
          _syncPhase(context, CustomerDisplayQrPhase.expired);
        }
      },
      child: BlocBuilder<PvsQrBloc, PvsQrState>(
        buildWhen: (previous, current) {
          if (previous.runtimeType != current.runtimeType) return true;
          if (current is PvsQrGenerated && previous is PvsQrGenerated) {
            return current.qrId != previous.qrId ||
                current.qrRaw != previous.qrRaw ||
                current.qrImageBase64 != previous.qrImageBase64;
          }
          if (current is PvsQrPaymentPending &&
              previous is PvsQrPaymentPending) {
            return current.qrId != previous.qrId ||
                current.qrRaw != previous.qrRaw ||
                current.qrImageBase64 != previous.qrImageBase64;
          }
          if (current is PvsQrPaymentApproved &&
              previous is PvsQrPaymentApproved) {
            return current.result != previous.result;
          }
          return true;
        },
        builder: (context, state) {
          if (state is PvsQrLoading) {
            return const PvsPaymentStatusView(
              icon: Icons.qr_code_2,
              color: Colors.blue,
              title: 'Pago con QR',
              subtitle: 'Generando código...',
            );
          }
          if (state is PvsQrGenerated || state is PvsQrPaymentPending) {
            final qrId = state is PvsQrGenerated
                ? state.qrId
                : (state as PvsQrPaymentPending).qrId;
            final qrImage = state is PvsQrGenerated
                ? state.qrImageBase64
                : (state as PvsQrPaymentPending).qrImageBase64;
            final isPending = state is PvsQrPaymentPending;

            if (qrImage == null || qrImage.isEmpty) {
              return PvsPaymentStatusView(
                icon: Icons.error_outline,
                color: Colors.red,
                title: 'Error',
                subtitle: 'La respuesta de PVS no incluye qrImage',
                primaryLabel: 'Reintentar',
                onPrimary: () => context.read<PvsQrBloc>().regenerate(),
                secondaryLabel: 'Cancelar',
                onSecondary: onCancelled,
              );
            }

            return PvsQrGeneratedView(
              key: ValueKey(qrId),
              totalAmount: totalAmount,
              qrId: qrId,
              qrImageBase64: qrImage,
              isPending: isPending,
              onCancelled: onCancelled,
            );
          }
          if (state is PvsQrPaymentApproved) {
            return PvsPaymentStatusView(
              icon: Icons.check_circle_outline,
              color: Colors.green,
              title: 'Pago aprobado',
              subtitle: 'El cobro PVS fue confirmado',
              detail: state.result.paymentId.isNotEmpty
                  ? 'ID: ${state.result.paymentId}'
                  : null,
              primaryLabel: 'Continuar',
              onPrimary: () => onApproved(state.result),
            );
          }
          if (state is PvsQrPaymentRejected) {
            return PvsPaymentStatusView(
              icon: Icons.cancel_outlined,
              color: Colors.red,
              title: 'Pago rechazado',
              subtitle: state.reason,
              primaryLabel: 'Cerrar',
              onPrimary: onCancelled,
            );
          }
          if (state is PvsQrExpired) {
            return PvsPaymentStatusView(
              icon: Icons.timer_off_outlined,
              color: Colors.orange,
              title: 'QR expirado',
              subtitle: 'El código QR venció. Regeneralo para continuar.',
              primaryLabel: 'Regenerar QR',
              onPrimary: () => context.read<PvsQrBloc>().regenerate(),
              secondaryLabel: 'Cancelar',
              onSecondary: onCancelled,
            );
          }
          if (state is PvsQrError) {
            return PvsPaymentStatusView(
              icon: Icons.error_outline,
              color: Colors.red,
              title: 'Error',
              subtitle: state.message,
              primaryLabel: 'Reintentar',
              onPrimary: () => context.read<PvsQrBloc>().regenerate(),
              secondaryLabel: 'Cancelar',
              onSecondary: onCancelled,
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
