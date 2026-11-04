import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/core/utils/extensions.dart';
import 'package:punto_venta_app/features/customer_display/domain/customer_display_prefs.dart';
import 'package:punto_venta_app/features/customer_display/domain/customer_display_service.dart';
import 'package:punto_venta_app/features/customer_display/domain/customer_display_snapshot.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/product/product_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/product/product_state.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/product/product_image.dart';
import 'package:punto_venta_app/injection_container.dart' as di;
import 'package:shared_preferences/shared_preferences.dart';

Future<void> showCustomerDisplayAdvertisingDialog(
  BuildContext context, {
  ProductBloc? productBloc,
}) {
  final bloc = productBloc ?? context.read<ProductBloc>();
  return showDialog<void>(
    context: context,
    builder: (_) => BlocProvider.value(
      value: bloc,
      child: const _CustomerDisplayAdvertisingDialog(),
    ),
  );
}

class _CustomerDisplayAdvertisingDialog extends StatefulWidget {
  const _CustomerDisplayAdvertisingDialog();

  @override
  State<_CustomerDisplayAdvertisingDialog> createState() =>
      _CustomerDisplayAdvertisingDialogState();
}

class _CustomerDisplayAdvertisingDialogState
    extends State<_CustomerDisplayAdvertisingDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _messageController;
  late final SharedPreferences _prefs;
  late int _idleSeconds;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _prefs = di.sl<SharedPreferences>();
    _titleController =
        TextEditingController(text: CustomerDisplayPrefs.adTitle(_prefs));
    _messageController =
        TextEditingController(text: CustomerDisplayPrefs.adMessage(_prefs));
    final savedIdle = CustomerDisplayPrefs.adIdleSeconds(_prefs);
    _idleSeconds = CustomerDisplayPrefs.idleSecondsOptions.contains(savedIdle)
        ? savedIdle
        : CustomerDisplayPrefs.defaultAdIdleSeconds;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  List<CustomerDisplayAdProduct> _onSaleFromBloc() {
    final state = context.read<ProductBloc>().state;
    if (state is! ProductLoaded) {
      return CustomerDisplayPrefs.adProducts(_prefs);
    }
    return CustomerDisplayPrefs.onSaleProductsFromCatalog(state.allProducts);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final title = _titleController.text.trim().isEmpty
          ? CustomerDisplayPrefs.defaultAdTitle
          : _titleController.text.trim();
      final message = _messageController.text.trim();
      final products = _onSaleFromBloc();

      await CustomerDisplayPrefs.saveAdvertising(
        _prefs,
        title: title,
        message: message,
        idleSeconds: _idleSeconds,
        products: products,
      );

      final service = di.sl<CustomerDisplayService>();
      if (service.isEnabled) {
        await service.sync(
          CustomerDisplaySnapshot.advertising(
            adTitle: title,
            adMessage: message,
            adProducts: products,
          ),
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            products.isEmpty
                ? 'Publicidad guardada (sin productos en oferta)'
                : 'Publicidad guardada: ${products.length} productos en oferta',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.75;

    return AlertDialog(
      title: const Text('Publicidad pantalla cliente'),
      content: SizedBox(
        width: AppDimensions.dialogWidth(context, 480),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'El carrusel muestra productos en oferta. '
                  'Fuera del POS siempre se muestra. En el POS, si el carrito '
                  'está vacío, actúa como pantalla de bloqueo tras el tiempo '
                  'configurado.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppDimensions.paddingM),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Título',
                    hintText: 'Promociones',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 60,
                ),
                const SizedBox(height: AppDimensions.paddingS),
                TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    labelText: 'Mensaje (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 120,
                ),
                const SizedBox(height: AppDimensions.paddingS),
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Bloqueo en POS (sin facturar)',
                    border: OutlineInputBorder(),
                    helperText:
                        'Tiempo con carrito vacío antes de mostrar publicidad',
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      value: _idleSeconds,
                      items: [
                        for (final seconds
                            in CustomerDisplayPrefs.idleSecondsOptions)
                          DropdownMenuItem(
                            value: seconds,
                            child: Text(
                              CustomerDisplayPrefs.idleSecondsLabel(seconds),
                            ),
                          ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _idleSeconds = value);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingM),
                BlocBuilder<ProductBloc, ProductState>(
                  builder: (context, state) {
                    final products = state is ProductLoaded
                        ? CustomerDisplayPrefs.onSaleProductsFromCatalog(
                            state.allProducts,
                          )
                        : CustomerDisplayPrefs.adProducts(_prefs);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Productos en oferta (${products.length})',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        _OnSaleProductsContainer(products: products),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }
}

/// Misma caja que el selector de clientes del PDV.
class _OnSaleProductsContainer extends StatelessWidget {
  const _OnSaleProductsContainer({required this.products});

  static const double listHeight = 220;

  final List<CustomerDisplayAdProduct> products;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: listHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: products.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No hay productos con is_on_sale = 1\nen el catálogo cargado',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          : ListView.separated(
              itemCount: products.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: Colors.grey.shade200,
              ),
              itemBuilder: (context, index) {
                final p = products[index];
                final hasImage =
                    p.imageUrl != null && p.imageUrl!.trim().isNotEmpty;
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    child: hasImage
                        ? ClipOval(
                            child: ProductImage(
                              imageUrl: p.imageUrl!,
                              fit: BoxFit.cover,
                              width: 40,
                              height: 40,
                            ),
                          )
                        : const Icon(
                            Icons.local_offer,
                            color: AppColors.primary,
                            size: 20,
                          ),
                  ),
                  title: Text(
                    p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    p.unitPrice.formatToCurrency(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'OFERTA',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
