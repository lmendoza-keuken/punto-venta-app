import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/utils/extensions.dart';
import 'package:punto_venta_app/features/auth/data/datasources/auth_local_datasources.dart';
import 'package:punto_venta_app/features/pos/data/datasources/price_list_local_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/printer_local_datasource.dart';
import 'package:punto_venta_app/features/pos/domain/entities/client.dart';
import 'package:punto_venta_app/features/pos/domain/entities/print_job.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/complete_order_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/send_invoice_usecase.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_state.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/printer/printer_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/printer/printer_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/printer/printer_state.dart';
import 'package:punto_venta_app/injection_container.dart' as di;

showConfirmDialog({
  required BuildContext context,
  Client? client,
}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return BlocProvider(
        create: (context) => di.sl<PrinterBloc>(),
        child: ConfirmDialogContent(
          client: client,
        ),
      );
    },
  );
}

class ConfirmDialogContent extends StatelessWidget {
  final Client? client;

  const ConfirmDialogContent({
    this.client,
  });

  @override
  Widget build(BuildContext context) {
    final cartState = context.read<CartBloc>().state;
    double displayTotal = 0.0;

    if (cartState is CartLoaded) {
      displayTotal = cartState.total;
    }

    final totalConIva = displayTotal; 

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
            Text('Total a cobrar: ${totalConIva.formatToCurrency()}'),
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
    try {
      final state = context.read<CartBloc>().state;
      if (state is! CartLoaded) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No hay artículos en el carrito'),
              backgroundColor: AppColors.error,
            ),
          );
          Navigator.of(context).pop();
        }
        return;
      }

      final cartState = state;
      final user = await di.sl<AuthLocalDataSource>().getCachedUser();
      final printerConfig =
          await di.sl<PrinterLocalDataSource>().getPrinterConfig();
      final priceList =
          await di.sl<PriceListLocalDataSource>().getCurrentPriceList();

      final totalTax = cartState.totalIva;

      final completeOrderUsecase = di.sl<CompleteOrderUsecase>();
      await completeOrderUsecase(
        items: cartState.items,
        logItems: cartState.log,
        total: cartState.total,
        clientName: client?.name,
        cashierName: user?.name ?? 'Desconocido',
      );

      final printJob = PrintJob(
        items: cartState.items,
        logItems: cartState.log,
        total: cartState.total,
        clientName: client?.name,
        client: client,
        priceListId: priceList,
        totalTax: totalTax,
        paymentMethod: 'Efectivo',
        cashierName: user?.name ?? 'Desconocido',
        cashierId: int.tryParse(user?.id ?? ''),
        timestamp: DateTime.now(),
        ticketId: DateTime.now().millisecondsSinceEpoch.toString(),
      );

      final sendInvoice = di.sl<SendInvoiceUseCase>();
      bool invoiceSent = false;
      
      try {
        invoiceSent = await sendInvoice(printJob);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: No se pudo enviar la factura - $e'),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 4),
            ),
          );
          Navigator.of(context).pop();
        }
        return;
      }

      if (!invoiceSent) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: La factura no se pudo enviar'),
              backgroundColor: AppColors.error,
            ),
          );
          Navigator.of(context).pop();
        }
        return;
      }

      if (context.mounted) {
        context.read<PrinterBloc>().add(PrintTicket(
              printJob: printJob,
              config: printerConfig,
            ));

        await context.read<PrinterBloc>().stream.firstWhere(
          (state) => state is PrinterSuccess || state is PrinterError,
        );

        context.read<CartBloc>().add(ClearCart());
        Navigator.of(context).pop();
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Venta procesada exitosamente'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar venta: $e'),
            backgroundColor: AppColors.error,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }
}
