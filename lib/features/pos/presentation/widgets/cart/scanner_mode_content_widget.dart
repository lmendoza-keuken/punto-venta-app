import 'package:flutter/material.dart';
import 'package:punto_venta_app/features/pos/domain/entities/cart_log_entry.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/last_scanned_product_preview.dart';

class ScannerModeContent extends StatelessWidget {
  final CartLogEntry? lastEntry;

  const ScannerModeContent({
    super.key,
    this.lastEntry,
  });

  @override
  Widget build(BuildContext context) {
    if (lastEntry == null) {
      return const _EmptyScannerState();
    }

    return LastScannedProductPreview(entry: lastEntry!);
  }
}

class _EmptyScannerState extends StatelessWidget {
  const _EmptyScannerState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.barcode_reader,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Modo escaneo de código de barras',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Escaneá un producto para verlo aquí',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
