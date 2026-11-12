import 'package:flutter/material.dart';
import 'package:punto_venta_app/features/pos/domain/entities/cart_log_entry.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/cart_empty_widget.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/last_scanned_product_preview.dart';

class ScannerModeContent extends StatelessWidget {
  final CartLogEntry? lastEntry;
  final bool dense;
  final double? lastSaleChange;

  const ScannerModeContent({
    super.key,
    this.lastEntry,
    this.dense = false,
    this.lastSaleChange,
  });

  @override
  Widget build(BuildContext context) {
    if (lastEntry == null) {
      return _EmptyScannerState(
        dense: dense,
        lastSaleChange: lastSaleChange,
      );
    }

    return LastScannedProductPreview(entry: lastEntry!, dense: dense);
  }
}

class _EmptyScannerState extends StatelessWidget {
  final bool dense;
  final double? lastSaleChange;

  const _EmptyScannerState({
    this.dense = false,
    this.lastSaleChange,
  });

  @override
  Widget build(BuildContext context) {
    final change = lastSaleChange;
    final hasChange = change != null && change > 0;

    if (dense) {
      if (hasChange) {
        return Padding(
          padding: const EdgeInsets.all(12),
          child: LastSaleChangeBanner(change: change, dense: true),
        );
      }
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (hasChange) ...[
              LastSaleChangeBanner(change: change),
              const SizedBox(height: 20),
            ] else ...[
              Icon(
                Icons.barcode_reader,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
            ],
            Text(
              hasChange
                  ? 'Escaneá un producto para continuar'
                  : 'Modo escaneo de código de barras',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            if (!hasChange) ...[
              const SizedBox(height: 8),
              Text(
                'Escaneá un producto para verlo aquí',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
