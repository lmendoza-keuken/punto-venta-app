import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/core/widgets/custom_text_field.dart';
import 'package:punto_venta_app/features/pos/domain/entities/product.dart';
// import 'package:punto_venta_app/features/stock/presentation/bloc/stock_bloc.dart';
// import 'package:punto_venta_app/features/stock/presentation/bloc/stock_event.dart';
// import 'package:uuid/uuid.dart';

class ProductFormDialog extends StatefulWidget {
  final Product? product;

  const ProductFormDialog({
    super.key,
    this.product,
  });

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codigoController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _precioController = TextEditingController();
  final _stockController = TextEditingController();
  final _categoriaController = TextEditingController();

  bool get isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _codigoController.text = widget.product!.id.toString();
      _descripcionController.text = widget.product!.descripcionComercial;
      _precioController.text = widget.product!.precio.toString();
      _stockController.text = widget.product!.stock.toString();
      _categoriaController.text = widget.product!.descripcionRubro;
    }
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _descripcionController.dispose();
    _precioController.dispose();
    _stockController.dispose();
    _categoriaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusL),
      ),
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppDimensions.borderRadiusL),
                  topRight: Radius.circular(AppDimensions.borderRadiusL),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isEditing ? Icons.edit : Icons.add_box,
                    color: Colors.white,
                  ),
                  const SizedBox(width: AppDimensions.paddingS),
                  Text(
                    isEditing ? 'Editar Producto' : 'Nuevo Producto',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CustomTextField(
                        controller: _codigoController,
                        label: 'Código',
                        hint: 'Ej: PROD001',
                        prefixIcon: Icon(Icons.qr_code),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El código es requerido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppDimensions.paddingM),
                      CustomTextField(
                        controller: _descripcionController,
                        label: 'Descripción',
                        hint: 'Nombre del producto',
                        prefixIcon: Icon(Icons.inventory_2),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'La descripción es requerida';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppDimensions.paddingM),
                      CustomTextField(
                        controller: _precioController,
                        label: 'Precio',
                        hint: '0.00',
                        prefixIcon: Icon(Icons.attach_money),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),

                          
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El precio es requerido';
                          }
                          final precio = double.tryParse(value);
                          if (precio == null || precio <= 0) {
                            return 'Ingrese un precio válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppDimensions.paddingM),
                      CustomTextField(
                        controller: _stockController,
                        label: 'Stock Inicial',
                        hint: '0',
                        prefixIcon: Icon(Icons.warehouse),
                        keyboardType: TextInputType.number,
                        
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El stock es requerido';
                          }
                          final stock = int.tryParse(value);
                          if (stock == null || stock < 0) {
                            return 'Ingrese un stock válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppDimensions.paddingM),
                      CustomTextField(
                        controller: _categoriaController,
                        label: 'Categoría (Opcional)',
                        hint: 'Ej: Bebidas, Alimentos, etc.',
                        prefixIcon: Icon(Icons.category),
                      ),
                    ],
                  ),
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
                    icon: Icon(isEditing ? Icons.save : Icons.add, color: Colors.white),
                    label: Text(isEditing ? 'Guardar' : 'Crear'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
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

    // final product = Product(
      
    //   id: isEditing ? widget.product!.id : const Uuid().v4(),
    //   codigo: int.parse(_codigoController.text.trim()),
    //   descripcion: _descripcionController.text.trim(),
    //   precio: double.parse(_precioController.text.trim()),
    //   stock: int.parse(_stockController.text.trim()),
    //   rubro: _categoriaController.text.trim().isEmpty
    //       ? null
    //       : _categoriaController.text.trim(),
    //   activo: true,
    //   createdAt: isEditing ? widget.product!.createdAt : DateTime.now(),
    //   updatedAt: DateTime.now(),
    // );

    // if (isEditing) {
    //   context.read<StockBloc>().add(UpdateProduct(product));
    // } else {
    //   context.read<StockBloc>().add(CreateProduct(product));
    // }

    Navigator.of(context).pop();
  }
}