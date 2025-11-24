import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos_flutter_app/core/constants/app_colors.dart';
import 'package:pos_flutter_app/core/utils/extensions.dart';
import 'package:pos_flutter_app/features/pos/domain/entities/client.dart';
import 'package:pos_flutter_app/features/pos/domain/entities/print_job.dart';
import 'package:pos_flutter_app/features/pos/domain/entities/printer_config.dart';
import 'package:pos_flutter_app/features/pos/domain/usecases/complete_order_usecase.dart';
import 'package:pos_flutter_app/features/pos/presentation/bloc/cart/cart_bloc.dart';
import 'package:pos_flutter_app/features/pos/presentation/bloc/cart/cart_event.dart';
import 'package:pos_flutter_app/features/pos/presentation/bloc/cart/cart_state.dart';
import 'package:pos_flutter_app/features/pos/presentation/bloc/printer/printer_bloc.dart';
import 'package:pos_flutter_app/features/pos/presentation/bloc/printer/printer_event.dart';
import 'package:pos_flutter_app/features/pos/presentation/bloc/printer/printer_state.dart';
import 'package:pos_flutter_app/injection_container.dart' as di;

showConfirmDialog({
  required double total,
  required BuildContext context,
  Client? client,
}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return BlocProvider(
        create: (context) => di.sl<PrinterBloc>(),
        child: _ConfirmDialogContent(
          total: total,
          client: client,
        ),
      );
    },
  );
}

class _ConfirmDialogContent extends StatelessWidget {
  final double total;
  final Client? client;

  const _ConfirmDialogContent({
    required this.total,
    this.client,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<PrinterBloc, PrinterState>(
      listener: (context, printerState) {
        if (printerState is PrinterSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(printerState.message),
              backgroundColor: AppColors.success,
            ),
          );
        } else if (printerState is PrinterError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(printerState.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: AlertDialog(
        title: const Text('Confirmar Venta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Total a cobrar: \$${total.formatToCurrency()}'),
            const SizedBox(height: 16),
            const Text('¿Deseas procesar esta venta?'),
            const SizedBox(height: 16),
            BlocBuilder<PrinterBloc, PrinterState>(
              builder: (context, printerState) {
                if (printerState is PrinterPrinting) {
                  return const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Imprimiendo...'),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          BlocBuilder<PrinterBloc, PrinterState>(
            builder: (context, printerState) {
              final isLoading = printerState is PrinterPrinting;

              return ElevatedButton(
                onPressed: isLoading ? null : () => _confirmSale(context),
                child: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Confirmar'),
              );
            },
          ),
        ],
      ),
    );
  }

  void _confirmSale(BuildContext context) async {
    final cartState = context.read<CartBloc>().state as CartLoaded;

    try {
      final completeOrderUsecase = di.sl<CompleteOrderUsecase>();
      await completeOrderUsecase(
        items: cartState.items,
        logItems: cartState.log,
        total: cartState.total,
        clientName: client?.name,
        cashierName: 'Brayan',
      );

      final printJob = PrintJob(
        items: cartState.items,
        logItems: cartState.log,
        total: cartState.total,
        clientName: client?.name,
        cashierName: 'Brayan',
        timestamp: DateTime.now(),
        ticketId: DateTime.now().millisecondsSinceEpoch.toString(),
      );

      const printerConfig = PrinterConfig(
        ip: '192.168.1.100', // Cambiar por la IP de impresora
        port: 9100, // Cambiar por el puerto de impresora
        timeout: 5000,
      );

      context.read<PrinterBloc>().add(PrintTicket(
            printJob: printJob,
            config: printerConfig,
          ));

      context.read<CartBloc>().add(ClearCart());

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Venta procesada exitosamente'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al procesar venta: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
