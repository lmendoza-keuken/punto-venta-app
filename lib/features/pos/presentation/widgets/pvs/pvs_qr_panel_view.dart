import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/pvs_qr/pvs_qr_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/pvs_qr/pvs_qr_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/pvs_qr/pvs_qr_state.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/pvs/pvs_qr_widget.dart';
import 'package:punto_venta_app/injection_container.dart' as di;

class PvsQrPanelView extends StatelessWidget {
  final double amount;
  final int paymentMethodId;
  final ValueChanged<PvsPaymentResult> onApproved;
  final VoidCallback onCancelled;

  const PvsQrPanelView({
    super.key,
    required this.amount,
    required this.paymentMethodId,
    required this.onApproved,
    required this.onCancelled,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<PvsQrBloc>()
        ..add(GeneratePvsQr(
          amount: amount,
          paymentMethodId: paymentMethodId,
        )),
      child: PvsQrWidget(
        totalAmount: amount,
        onApproved: onApproved,
        onCancelled: onCancelled,
      ),
    );
  }
}
