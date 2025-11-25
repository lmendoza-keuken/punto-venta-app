import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/core/utils/extensions.dart';
import 'package:punto_venta_app/features/pos/domain/entities/completed_order.dart';
import 'package:punto_venta_app/features/pos/domain/entities/print_job.dart';
import 'package:punto_venta_app/features/pos/domain/entities/printer_config.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/printer/printer_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/printer/printer_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/printer/printer_state.dart';
import 'package:punto_venta_app/injection_container.dart' as di;

class TicketPreviewDialog extends StatelessWidget {
  final CompletedOrder order;

  const TicketPreviewDialog({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<PrinterBloc>(),
      child: _TicketPreviewContent(order: order),
    );
  }
}

class _TicketPreviewContent extends StatelessWidget {
  final CompletedOrder order;

  const _TicketPreviewContent({required this.order});

  @override
  Widget build(BuildContext context) {
    return BlocListener<PrinterBloc, PrinterState>(
      listener: (context, state) {
        if (state is PrinterSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (state is PrinterError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Dialog(
        child: Container(
          width: 450,
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            children: [
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
                  child: _buildTicketContent(context),
                ),
              ),

              // Actions
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: BlocBuilder<PrinterBloc, PrinterState>(
                  builder: (context, state) {
                    final isLoading = state is PrinterPrinting;

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: isLoading
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: const Text('Cerrar'),
                        ),
                        ElevatedButton.icon(
                          onPressed: isLoading
                              ? null
                              : () => _handlePrint(context),
                          icon: isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Icon(
                                  Icons.print,
                                  color: Colors.white,
                                ),
                          label: Text(isLoading ? 'Imprimiendo...' : 'Imprimir'),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handlePrint(BuildContext context) {
    // Crear PrintJob desde CompletedOrder
    final printJob = PrintJob(
      items: order.items,
      logItems: order.logs,
      total: order.total,
      clientName: order.clientName,
      totalTax: order.totalTax,
      paymentMethod: order.paymentMethod,
      cashierName: order.cashierName,
      timestamp: order.completedAt,
      ticketId: order.id,
    );

    // Configuración de la impresora
    const printerConfig = PrinterConfig(
      ip: '192.168.0.230', // Cambiar por tu IP
      port: 9100,
      timeout: 10000,
    );

    // Disparar evento de impresión
    context.read<PrinterBloc>().add(PrintTicket(
          printJob: printJob,
          config: printerConfig,
        ));
  }

  Widget _buildTicketContent(BuildContext context) {
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
            // Header del negocio
            Center(
              child: Column(
                children: [
                  const Text(
                    'SOLUCIONES INFORMATICAS',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'KEUKEN, S.A.',
                    style: TextStyle(
                      fontSize: 18,
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
            Text('Orden: ${order.orderNumber}'),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    'Fecha: ${DateFormat('dd/MM/yyyy').format(order.completedAt)}'),
                Text('Hora: ${DateFormat('HH:mm:ss').format(order.completedAt)}'),
              ],
            ),
            Text('Cajero: ${order.cashierName}'),
            if (order.clientName != null && order.clientName!.isNotEmpty)
              Text('Cliente: ${order.clientName}'),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(
                color: Colors.black,
              ),
            ),

            // Items
            ...order.items
                .map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.product.descripcion,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '  ${item.quantity} x ${item.product.precio.formatToCurrency()}',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[600]),
                              ),
                              Text(
                                item.totalPrice.formatToCurrency(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ))
                .toList(),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
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
                thickness: 2,
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

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(
                color: Colors.black,
                thickness: 2,
              ),
            ),

            const SizedBox(height: 8),

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
