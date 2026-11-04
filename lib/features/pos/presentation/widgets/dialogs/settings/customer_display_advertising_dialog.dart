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
  late final TextEditingController _searchController;
  late final SharedPreferences _prefs;
  late int _idleSeconds;
  late Set<int> _selectedIds;
  bool _saving = false;
  bool _selectionInitialized = false;

  @override
  void initState() {
    super.initState();
    _prefs = di.sl<SharedPreferences>();
    _titleController =
        TextEditingController(text: CustomerDisplayPrefs.adTitle(_prefs));
    _messageController =
        TextEditingController(text: CustomerDisplayPrefs.adMessage(_prefs));
    _searchController = TextEditingController();
    final savedIdle = CustomerDisplayPrefs.adIdleSeconds(_prefs);
    _idleSeconds = CustomerDisplayPrefs.idleSecondsOptions.contains(savedIdle)
        ? savedIdle
        : CustomerDisplayPrefs.defaultAdIdleSeconds;

    final saved = CustomerDisplayPrefs.adProductsOrNull(_prefs);
    if (saved != null && saved.isNotEmpty) {
      _selectedIds = saved.map((p) => p.productId).toSet();
      _selectionInitialized = true;
    } else {
      _selectedIds = <int>{};
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<CustomerDisplayAdProduct> _catalogOnSale() {
    final state = context.read<ProductBloc>().state;
    if (state is! ProductLoaded) return const [];
    return CustomerDisplayPrefs.onSaleProductsFromCatalog(state.allProducts);
  }

  void _ensureSelection(List<CustomerDisplayAdProduct> catalog) {
    if (_selectionInitialized || catalog.isEmpty) return;
    _selectedIds = catalog.map((p) => p.productId).toSet();
    _selectionInitialized = true;
  }

  List<CustomerDisplayAdProduct> _selectedProducts(
    List<CustomerDisplayAdProduct> catalog,
  ) {
    final byId = <int, CustomerDisplayAdProduct>{
      for (final product in catalog) product.productId: product,
    };
    return [
      for (final id in _selectedIds)
        if (byId.containsKey(id)) byId[id]!,
    ];
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final title = _titleController.text.trim().isEmpty
          ? CustomerDisplayPrefs.defaultAdTitle
          : _titleController.text.trim();
      final message = _messageController.text.trim();
      final catalog = _catalogOnSale();
      _ensureSelection(catalog);
      final products = _selectedIds.isEmpty
          ? catalog
          : _selectedProducts(catalog);

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
                ? 'Publicidad guardada (sin ofertas en catálogo)'
                : _selectedIds.isEmpty
                    ? 'Publicidad guardada: todas las ofertas (${products.length})'
                    : 'Publicidad guardada: ${products.length} productos',
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
                  'Elegí qué productos en oferta mostrar en el carrusel. '
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
                    final catalog = state is ProductLoaded
                        ? CustomerDisplayPrefs.onSaleProductsFromCatalog(
                            state.allProducts,
                          )
                        : CustomerDisplayPrefs.adProducts(_prefs);

                    if (!_selectionInitialized && catalog.isNotEmpty) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted || _selectionInitialized) return;
                        setState(() {
                          _selectedIds =
                              catalog.map((p) => p.productId).toSet();
                          _selectionInitialized = true;
                        });
                      });
                    }

                    final query = _searchController.text.trim().toLowerCase();
                    final filtered = query.isEmpty
                        ? catalog
                        : catalog.where((p) {
                            final name = p.name.toLowerCase();
                            final id = p.productId.toString();
                            return name.contains(query) || id.contains(query);
                          }).toList();

                    final selectedCount = catalog
                        .where((p) => _selectedIds.contains(p.productId))
                        .length;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Productos en oferta ($selectedCount/${catalog.length})',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            TextButton(
                              onPressed: catalog.isEmpty
                                  ? null
                                  : () {
                                      setState(() {
                                        _selectedIds = catalog
                                            .map((p) => p.productId)
                                            .toSet();
                                        _selectionInitialized = true;
                                      });
                                    },
                              child: const Text('Todos'),
                            ),
                            TextButton(
                              onPressed: _selectedIds.isEmpty
                                  ? null
                                  : () {
                                      setState(() {
                                        _selectedIds.clear();
                                        _selectionInitialized = true;
                                      });
                                    },
                              child: const Text('Ninguno'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _OnSaleProductsContainer(
                          products: filtered,
                          selectedIds: _selectedIds,
                          searchController: _searchController,
                          onSearchChanged: (_) => setState(() {}),
                          onToggle: (productId, selected) {
                            setState(() {
                              _selectionInitialized = true;
                              if (selected) {
                                _selectedIds.add(productId);
                              } else {
                                _selectedIds.remove(productId);
                              }
                            });
                          },
                        ),
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

class _OnSaleProductsContainer extends StatelessWidget {
  const _OnSaleProductsContainer({
    required this.products,
    required this.selectedIds,
    required this.searchController,
    required this.onSearchChanged,
    required this.onToggle,
  });

  static const double listHeight = 220;

  final List<CustomerDisplayAdProduct> products;
  final Set<int> selectedIds;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final void Function(int productId, bool selected) onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Buscar por nombre o ID',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpiar',
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          searchController.clear();
                          onSearchChanged('');
                        },
                      ),
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ),
          SizedBox(
            height: listHeight,
            child: products.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        searchController.text.trim().isEmpty
                            ? 'No hay productos con is_on_sale = 1\nen el catálogo cargado'
                            : 'Sin resultados para la búsqueda',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
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
                      final selected = selectedIds.contains(p.productId);
                      final hasImage = p.imageUrl != null &&
                          p.imageUrl!.trim().isNotEmpty;
                      return CheckboxListTile(
                        dense: true,
                        value: selected,
                        onChanged: (value) {
                          onToggle(p.productId, value ?? false);
                        },
                        secondary: CircleAvatar(
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.12),
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
                          'ID ${p.productId} · ${p.unitPrice.formatToCurrency()}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        controlAffinity: ListTileControlAffinity.trailing,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
