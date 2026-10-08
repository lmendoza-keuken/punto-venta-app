import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/utils/extensions.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/pvs_qr/pvs_qr_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/pvs_qr/pvs_qr_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/pvs_qr/pvs_qr_state.dart';

/// Muestra el QR oficial de PVS desde `qrImage` (PNG Base64).
/// Equivalente a: `<img src="data:image/png;base64,{qrImage}" />`
class PvsQrGeneratedView extends StatefulWidget {
  const PvsQrGeneratedView({
    super.key,
    required this.totalAmount,
    required this.qrId,
    required this.qrImageBase64,
    this.isPending = false,
    this.onCancelled,
  });

  final double totalAmount;
  final String qrId;
  final String qrImageBase64;
  final bool isPending;
  final VoidCallback? onCancelled;

  @override
  State<PvsQrGeneratedView> createState() => _PvsQrGeneratedViewState();
}

class _PvsQrGeneratedViewState extends State<PvsQrGeneratedView> {
  late final Uint8List _qrBytes;

  @override
  void initState() {
    super.initState();
    _qrBytes = base64Decode(widget.qrImageBase64);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final hasBoundedHeight = constraints.maxHeight.isFinite;
        final qrSize =
            hasBoundedHeight && constraints.maxHeight < 560 ? 200.0 : 260.0;

        final content = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/pvs_logo.png',
              height: 60,
            ),
            const SizedBox(height: 10),
            Text(
              widget.isPending
                  ? 'Pago en proceso...'
                  : 'Escanea el código QR para pagar',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(12),
              child: Image.memory(
                _qrBytes,
                width: qrSize,
                height: qrSize,
                fit: BoxFit.contain,
                gaplessPlayback: true,
              ),
            ),
            const SizedBox(height: 10),
            BlocSelector<PvsQrBloc, PvsQrState, int>(
              selector: (state) {
                if (state is PvsQrGenerated) return state.secondsRemaining;
                if (state is PvsQrPaymentPending) {
                  return state.secondsRemaining;
                }
                return 0;
              },
              builder: (context, secondsRemaining) {
                final m =
                    (secondsRemaining ~/ 60).toString().padLeft(2, '0');
                final s =
                    (secondsRemaining % 60).toString().padLeft(2, '0');
                return Text(
                  'Expira en $m:$s',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: secondsRemaining <= 30
                        ? Colors.red
                        : Colors.black87,
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'Monto a pagar',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  Text(
                    widget.totalAmount.formatToCurrency(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontSize: 36,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        );

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(child: content),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    context
                        .read<PvsQrBloc>()
                        .add(const CancelPvsQrSession());
                    widget.onCancelled?.call();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cerrar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
