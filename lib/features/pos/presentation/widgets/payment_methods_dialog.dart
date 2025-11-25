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
              Text(
                'Total a cobrar: ${widget.total.formatToCurrency()}',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('Seleccione los metodos de pago para esta venta.'),
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
