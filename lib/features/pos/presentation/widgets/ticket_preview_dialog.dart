import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/core/utils/extensions.dart';
import 'package:punto_venta_app/features/pos/domain/entities/completed_order.dart';

class TicketPreviewDialog extends StatelessWidget {
  final CompletedOrder order;

  const TicketPreviewDialog({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 400,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppDimensions.borderRadiusL),
                  topRight: Radius.circular(AppDimensions.borderRadiusL),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt, color: AppColors.primary),
                  const SizedBox(width: AppDimensions.paddingS),
                  Text(
                    'Ticket - ${order.orderNumber}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Ticket content
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                child: _buildTicketContent(),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cerrar'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Aquí iría la lógica de impresión
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Ticket reimimpreso exitosamente'),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.print,
                      color: Colors.white,
                    ),
                    label: const Text('Imprimir'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketContent() {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header del negocio (Hardcoded por ahora)
            Center(
              child: Column(
                children: [
                  const Text(
                    'POS System',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text('Sistema de Punto de Venta'),
                  const Text('Tel: (555) 123-4567'),
                  const SizedBox(height: 16),
                  Container(
                    height: 1,
                    color: Colors.black,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ],
              ),
            ),

            // Información de la orden
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Orden: ${order.orderNumber}'),
                Text(
                    'Fecha: ${DateFormat('dd/MM/yyyy').format(order.completedAt)}'),
              ],
            ),
            Text('Hora: ${DateFormat('HH:mm:ss').format(order.completedAt)}'),
            Text('Cajero: ${order.cashierName}'),
            if (order.clientName != null) Text('Cliente: ${order.clientName}'),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(
                color: Colors.black,
              ),
            ),

            // Items
            ...order.items
                .map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.product.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  '${item.product.precio.formatToCurrency()} x ${item.quantity}',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            item.totalPrice.formatToCurrency(),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ))
                .toList(),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(
                color: Colors.black,
              ),
            ),

            // Totales
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal:'),
                Text((order.total - order.totalTax).formatToCurrency()),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('IVA (21%):'),
                Text(order.totalTax.formatToCurrency()),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(
                color: Colors.black,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTAL:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  order.total.formatToCurrency(),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Información adicional
            Text('Método de pago: ${order.paymentMethod}'),
            Text('Total de artículos: ${order.totalItems}'),

            const SizedBox(height: 16),
            const Center(
              child: Text(
                '¡Gracias por su compra!',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
