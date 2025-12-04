import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/core/widgets/custom_text_field.dart';
import 'package:punto_venta_app/features/pos/domain/entities/product.dart';
import 'package:punto_venta_app/features/stock/presentation/bloc/stock_bloc.dart';
import 'package:punto_venta_app/features/stock/presentation/bloc/stock_event.dart';

enum StockOperationType {
  add,
  remove,
  adjust,
}

class StockMovementDialog extends StatefulWidget {
  final Product product;
  final StockOperationType operationType;

  const StockMovementDialog({
    super.key,
    required this.product,
    required this.operationType,
  });

  @override
  State<StockMovementDialog> createState() => _StockMovementDialogState();
}

class _StockMovementDialogState extends State<StockMovementDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  String get _title {
    switch (widget.operationType) {
      case StockOperationType.add:
        return 'Agregar Stock';
      case StockOperationType.remove:
        return 'Quitar Stock';
      case StockOperationType.adjust:
        return 'Ajustar Stock';
    }
  }

  IconData get _icon {
    switch (widget.operationType) {
      case StockOperationType.add:
        return Icons.add_circle;
      case StockOperationType.remove:
        return Icons.remove_circle;
      case StockOperationType.adjust:
        return Icons.tune;
    }
  }

  Color get _color {
    switch (widget.operationType) {
      case StockOperationType.add:
        return AppColors.success;
      case StockOperationType.remove:
        return AppColors.error;
      case StockOperationType.adjust:
        return AppColors.warning;
    }
  }

  String get _quantityLabel {
    switch (widget.operationType) {
      case StockOperationType.add:
        return 'Cantidad a agregar';
      case StockOperationType.remove:
        return 'Cantidad a quitar';
      case StockOperationType.adjust:
        return 'Nuevo stock';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusL),
      ),
      child: Container(
        width: 450,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              decoration: BoxDecoration(
                color: _color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppDimensions.borderRadiusL),
                  topRight: Radius.circular(AppDimensions.borderRadiusL),
                ),
              ),
              child: Row(
                children: [
                  Icon(_icon, color: Colors.white),
                  const SizedBox(width: AppDimensions.paddingS),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          widget.product.description,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Current stock info
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              color: Colors.grey.shade50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Stock actual: ',
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    '${widget.product.stock}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

            // Form
            Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CustomTextField(
                      controller: _quantityController,
                      label: _quantityLabel,
                      hint: '0',
                      prefixIcon: Icon(Icons.tag),
                      keyboardType: TextInputType.number,
                     
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'La cantidad es requerida';
                        }
                        final quantity = int.tryParse(value);
                        if (quantity == null || quantity <= 0) {
                          return 'Ingrese una cantidad válida';
                        }

                        if (widget.operationType == StockOperationType.remove) {
                          if (quantity > widget.product.stock) {
                            return 'Stock insuficiente (disponible: ${widget.product.stock})';
                          }
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: AppDimensions.paddingM),
                    CustomTextField(
                      controller: _reasonController,
                      label: 'Motivo',
                      hint: 'Descripción del movimiento',
                      prefixIcon: Icon(Icons.description),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El motivo es requerido';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: AppDimensions.paddingS),
                  ElevatedButton.icon(
                    onPressed: _handleSubmit,
                    icon: Icon(_icon, color: Colors.white),
                    label: const Text('Confirmar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingL,
                        vertical: AppDimensions.paddingM,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    final quantity = int.parse(_quantityController.text.trim());
    final reason = _reasonController.text.trim();

    switch (widget.operationType) {
      case StockOperationType.add:
        context.read<StockBloc>().add(AddStock(
              productCodigo: widget.product.id,
              quantity: quantity,
              reason: reason,
            ));
        break;
      case StockOperationType.remove:
        context.read<StockBloc>().add(RemoveStock(
              productCodigo: widget.product.id,
              quantity: quantity,
              reason: reason,
            ));
        break;
      case StockOperationType.adjust:
        context.read<StockBloc>().add(AdjustStock(
              productCodigo: widget.product.id,
              newStock: quantity,
              reason: reason,
            ));
        break;
    }

    Navigator.of(context).pop();
  }
}