import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/mercado_pago_qr/mercado_pago_qr_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/mercado_pago_qr/mercado_pago_qr_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/mercado_pago_qr/mercado_pago_qr_state.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/mercado_pago/mercado_pago_qr_widget.dart';
import 'package:punto_venta_app/injection_container.dart' as di;

Future<MpPaymentResult?> showMercadoPagoQrDialog({
  required BuildContext context,
  required double amount,
}) {
  return showDialog<MpPaymentResult>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return BlocProvider(
        create: (_) => di.sl<MercadoPagoQrBloc>()
          ..add(GenerateMercadoPagoQr(amount: amount)),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 420,
              maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.9,
            ),
            child: SizedBox(
              height: MediaQuery.sizeOf(dialogContext).height * 0.85,
              child: MercadoPagoQrWidget(
                totalAmount: amount,
                onApproved: (result) {
                  Navigator.of(dialogContext).pop(result);
                },
                onCancelled: () {
                  Navigator.of(dialogContext).pop();
                },
              ),
            ),
          ),
        ),
      );
    },
  );
}
