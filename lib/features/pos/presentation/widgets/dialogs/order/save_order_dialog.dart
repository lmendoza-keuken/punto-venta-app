import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/core/utils/extensions.dart';
import 'package:punto_venta_app/core/widgets/custom_text_field.dart';
import 'package:punto_venta_app/features/pos/domain/entities/cart_item.dart';
import 'package:punto_venta_app/features/pos/domain/entities/cart_log_entry.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/saved_orders/saved_orders_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/saved_orders/saved_orders_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/saved_orders/saved_orders_state.dart';

class SaveOrderDialog extends StatefulWidget {
  final List<CartItem> cartItems;
  final List<CartLogEntry> cartLogItems;
  final double total;
  final String? clientName;

  const SaveOrderDialog({
    super.key,
    required this.cartItems,
    required this.cartLogItems,
    required this.total,
    this.clientName,
  });

  @override
  State<SaveOrderDialog> createState() => _SaveOrderDialogState();
}

class _SaveOrderDialogState extends State<SaveOrderDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _clientController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _clientController.text = widget.clientName ?? '';

    // Generar nombre por defecto
    final now = DateTime.now();
    _nameController.text =
        'Pedido ${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _clientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final availableHeight = screenHeight - keyboardHeight - 200;

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
            Text('Guardar Pedido'),
          ],
        ),
        content: SizedBox(
          width: 400,
          height: availableHeight.clamp(250.0, 400.0),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Información del pedido
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.paddingM),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.borderRadiusM),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Artículos:',
                                style: Theme.of(context).textTheme.titleMedium),
                            Text('${widget.cartItems.length}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total:',
                                style: Theme.of(context).textTheme.titleMedium),
                            Text(
                              widget.total.formatToCurrency(),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingM),

                  // Nombre del pedido
                  CustomTextField(
                    label: 'Nombre del pedido *',
                    controller: _nameController,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El nombre del pedido es requerido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppDimensions.paddingM),

                  // Cliente (opcional)
                  CustomTextField(
                    label: 'Cliente (opcional)',
                    controller: _clientController,
                    hint: 'Nombre del cliente',
                  ),
                ],
              ),
            ),
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
                onPressed: isLoading ? null : _saveOrder,
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

  void _saveOrder() {
    if (_formKey.currentState!.validate()) {
      context.read<SavedOrdersBloc>().add(
            SaveCurrentOrder(
              name: _nameController.text,
              items: widget.cartItems,
              logItems: widget.cartLogItems,
              total: widget.total,
              clientName: _clientController.text.trim().isEmpty
                  ? null
                  : _clientController.text.trim(),
            ),
          );
      context.read<CartBloc>().add(ClearCart());
    }
  }
}
