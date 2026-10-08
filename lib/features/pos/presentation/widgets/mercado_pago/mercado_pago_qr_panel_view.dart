import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/mercado_pago_qr/mercado_pago_qr_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/mercado_pago_qr/mercado_pago_qr_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/mercado_pago_qr/mercado_pago_qr_state.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/mercado_pago/mercado_pago_qr_widget.dart';
import 'package:punto_venta_app/injection_container.dart' as di;

/// Vista embebible del cobro QR (misma UI que el dialog, sin overlay).
class MercadoPagoQrPanelView extends StatelessWidget {
  final double amount;
  final ValueChanged<MpPaymentResult> onApproved;
  final VoidCallback onCancelled;

  const MercadoPagoQrPanelView({
    super.key,
    required this.amount,
    required this.onApproved,
    required this.onCancelled,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<MercadoPagoQrBloc>()
        ..add(GenerateMercadoPagoQr(amount: amount)),
      child: MercadoPagoQrWidget(
        totalAmount: amount,
        onApproved: onApproved,
        onCancelled: onCancelled,
      ),
    );
  }
}
