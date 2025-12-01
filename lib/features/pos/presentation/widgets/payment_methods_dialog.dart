import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/core/utils/extensions.dart';
import 'package:punto_venta_app/features/pos/domain/entities/client.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/saved_orders/saved_orders_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/saved_orders/saved_orders_state.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/sale_confirm_dialog.dart';

class PaymentMethodsDialog extends StatefulWidget {
  final double total;
  final Client? client;

  const PaymentMethodsDialog({super.key, required this.total, this.client});

  @override
  State<PaymentMethodsDialog> createState() => _PaymentMethodsDialogState();
}

class _PaymentMethodsDialogState extends State<PaymentMethodsDialog> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SavedOrdersBloc, SavedOrdersState>(
      listener: (context, state) {
        if (state is OrderSaved) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (state is SavedOrdersError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.save, color: AppColors.primary),
            SizedBox(width: AppDimensions.paddingS),
            Text('Metodos de Pago'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // const Text('Seleccione los metodos de pago para esta venta.'),
              const SizedBox(height: 12),
              Row(
                children: const [
                  Icon(Icons.info_outline, size: 18, color: AppColors.primary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Por el momento solo está habilitado el pago en efectivo.',
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              ListTile(
                leading:
                    const Icon(Icons.attach_money, color: AppColors.primary),
                title: const Text('Efectivo'),
                subtitle: const Text('Opción habilitada'),
                trailing:
                    const Icon(Icons.check_circle, color: AppColors.success),
              ),
              ListTile(
                leading: const Icon(Icons.credit_card, color: Colors.grey),
                title: const Text('Tarjeta (no disponible)'),
                enabled: false,
              ),
              ListTile(
                leading: const Icon(Icons.phone_iphone, color: Colors.grey),
                title: const Text('MercadoPago / QR (no disponible)'),
                enabled: false,
              ),
              const SizedBox(height: 15),
              Builder(
                builder: (context) {
                  final iva = widget.total * 0.21;
                  final totalConIva = widget.total + iva;
                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Subtotal:',
                              style: TextStyle(color: Colors.grey[700])),
                          Text(widget.total.formatToCurrency(),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('IVA (21%):',
                              style: TextStyle(color: Colors.grey[700])),
                          Text(iva.formatToCurrency(),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Divider(height: 1, color: Colors.grey[300]),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total a cobrar:',
                              style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600) ??
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          Text(totalConIva.formatToCurrency(),
                              style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold) ??
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          BlocBuilder<SavedOrdersBloc, SavedOrdersState>(
            builder: (context, state) {
              final isLoading = state is SavedOrdersLoading;

              return ElevatedButton(
                onPressed: isLoading ? null : _savePaymentMethod,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                ),
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
                    : const Text('Guardar'),
              );
            },
          ),
        ],
      ),
    );
  }

  void _savePaymentMethod() {
    showConfirmDialog(
        total: widget.total, context: context, client: widget.client);
  }
}
