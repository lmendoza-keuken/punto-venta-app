import 'package:flutter/material.dart';
import 'package:punto_venta_app/features/pos/domain/entities/cart_log_entry.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/last_scanned_product_preview.dart';

class ScannerModeContent extends StatelessWidget {
  final CartLogEntry? lastEntry;
  final bool dense;

  const ScannerModeContent({
    super.key,
    this.lastEntry,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    if (lastEntry == null) {
      return _EmptyScannerState(dense: dense);
    }

    return LastScannedProductPreview(entry: lastEntry!, dense: dense);
  }
}

class _EmptyScannerState extends StatelessWidget {
  final bool dense;

  const _EmptyScannerState({this.dense = false});

  @override
  Widget build(BuildContext context) {
    if (dense) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.barcode_reader, size: 36, color: Colors.grey.shade400),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Escaneá un producto para verlo aquí',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ),
          ],
        ),
      );
    }

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
