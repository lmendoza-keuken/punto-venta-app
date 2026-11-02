import 'package:barcode/barcode.dart';
import 'package:flutter/material.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/features/customer_display/presentation/widgets/customer_display_qr_brand.dart';

/// Panel QR para Mercado Pago / PVS en la pantalla cliente.
class CustomerDisplayQrPanel extends StatelessWidget {
  const CustomerDisplayQrPanel({
    super.key,
    required this.label,
    this.payload,
    this.totalLabel,
  });

  final String label;
  final String? payload;
  final String? totalLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPayload = payload != null && payload!.trim().isNotEmpty;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const headerReserve = 100.0;
            final available = constraints.maxHeight.isFinite
                ? constraints.maxHeight - headerReserve
                : 200.0;
            final side = available.clamp(120.0, 240.0);

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomerDisplayQrBrand(label: label, height: 52),
                const SizedBox(height: 8),
                Text(
                  'Escaneá el código para pagar',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (totalLabel != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    totalLabel!,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                if (hasPayload)
                  _QrCodeImage(data: payload!, size: side)
                else
                  Container(
                    width: side,
                    height: side,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.textHint,
                        width: 1.5,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.qr_code_scanner,
                            size: (side * 0.28).clamp(36.0, 64.0),
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Generando código\nde $label...',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _QrCodeImage extends StatelessWidget {
  const _QrCodeImage({required this.data, required this.size});

  final String data;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: CustomPaint(
        painter: _BarcodeQrPainter(data),
        size: Size.square(size - 24),
      ),
    );
  }
}

class _BarcodeQrPainter extends CustomPainter {
  _BarcodeQrPainter(this.data);

  final String data;

  @override
  void paint(Canvas canvas, Size size) {
    final qr = Barcode.qrCode();
    final paint = Paint()
      ..color = Colors.black
      ..isAntiAlias = false;
    try {
      for (final element in qr.make(data, width: size.width, height: size.height)) {
        if (element is BarcodeBar && element.black) {
          canvas.drawRect(
            Rect.fromLTWH(
              element.left,
              element.top,
              element.width,
              element.height,
            ),
            paint,
          );
        }
      }
    } catch (_) {
      final fallback = Paint()
        ..color = Colors.grey.shade400
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawRect(Offset.zero & size, fallback);
    }
  }

  @override
  bool shouldRepaint(covariant _BarcodeQrPainter oldDelegate) =>
      oldDelegate.data != data;
}
