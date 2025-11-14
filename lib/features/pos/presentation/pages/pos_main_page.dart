import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_flutter_app/app/routes/route_paths.dart';
import 'package:pos_flutter_app/core/constants/app_colors.dart';
import 'package:pos_flutter_app/core/constants/app_dimensions.dart';
import 'package:pos_flutter_app/core/constants/app_string.dart';
import 'package:pos_flutter_app/core/widgets/dynamic_date_time.dart';
import 'package:pos_flutter_app/features/auth/prensetation/bloc/auth_bloc.dart';
import 'package:pos_flutter_app/features/auth/prensetation/bloc/auth_event.dart';
import 'package:pos_flutter_app/features/pos/domain/entities/saved_order.dart';
import 'package:pos_flutter_app/features/pos/domain/usecases/complete_order_usecase.dart';
import 'package:pos_flutter_app/features/pos/presentation/bloc/cart/cart_bloc.dart';
import 'package:pos_flutter_app/features/pos/presentation/bloc/cart/cart_event.dart';
import 'package:pos_flutter_app/features/pos/presentation/bloc/cart/cart_state.dart';
import 'package:pos_flutter_app/features/pos/presentation/bloc/product/product_bloc.dart';
import 'package:pos_flutter_app/features/pos/presentation/bloc/product/product_event.dart';
import 'package:pos_flutter_app/features/pos/presentation/bloc/product/product_state.dart';
import 'package:pos_flutter_app/features/pos/presentation/bloc/reports/reports_bloc.dart';
import 'package:pos_flutter_app/features/pos/presentation/bloc/ui/ui_bloc.dart';
import 'package:pos_flutter_app/features/pos/presentation/bloc/ui/ui_event.dart';
import 'package:pos_flutter_app/features/pos/presentation/widgets/action_buttons.dart';
import 'package:pos_flutter_app/features/pos/presentation/widgets/cart_panel.dart';
import 'package:pos_flutter_app/features/pos/presentation/widgets/category_tabs.dart';
import 'package:pos_flutter_app/features/pos/presentation/widgets/enchanced_search_bar.dart';
import 'package:pos_flutter_app/features/pos/presentation/widgets/load_saved_orders_dialog.dart';
import 'package:pos_flutter_app/features/pos/presentation/widgets/product_grid.dart';
import 'package:pos_flutter_app/features/pos/presentation/widgets/reports_dialog.dart';
import 'package:pos_flutter_app/features/pos/presentation/widgets/save_order_dialog.dart';
import 'package:pos_flutter_app/injection_container.dart' as di;

class PosMainPage extends StatefulWidget {
  const PosMainPage({super.key});

  @override
  State<PosMainPage> createState() => _PosMainPageState();
}

class _PosMainPageState extends State<PosMainPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<ProductBloc>().add(LoadProducts());

    if (context.read<CartBloc>().state is! CartLoaded) {
      context.read<CartBloc>().add(ClearCart());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildClientInfo(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Responsive: cambiar layout según el ancho de pantalla
                if (constraints.maxWidth > 1200) {
                  return Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildCatalogSection(),
                      ),
                      const SizedBox(
                        width: AppDimensions.cartPanelWidth * 1.5,
                        child: CartPanel(),
                      ),
                    ],
                  );
                } else if (constraints.maxWidth > 800) {
                  return Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildCatalogSection(),
                      ),
                      const SizedBox(
                        width: AppDimensions.cartPanelWidth * 0.85,
                        child: CartPanel(),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildCatalogSection(),
                      ),
                      Container(
                        height: 200,
                        child: const CartPanel(),
                      ),
                    ],
                  );
                }
              },
            ),
          ),
          _buildActionButtons(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            children: [
              const Icon(
                Icons.point_of_sale,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppDimensions.paddingS),
              const Text(AppStrings.appName),
              const Spacer(),

              // Responsive: mostrar diferentes elementos según el ancho
              if (constraints.maxWidth > 600) ...[
                Text(
                  'Cajero: Brayan',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(width: AppDimensions.paddingS),
                Text(
                  '|',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(width: AppDimensions.paddingS),
                Text(
                  'Caja: 1',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(width: AppDimensions.paddingM),
              ],

              // Fecha y hora - responsive
              if (constraints.maxWidth > 400)
                DynamicDateTime(
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: constraints.maxWidth > 600 ? 14 : 12,
                      ),
                )
              else
                DynamicDateTime(
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                      ),
                ),
            ],
          );
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: _showLogoutDialog,
        ),
        const SizedBox(width: AppDimensions.paddingS),
      ],
    );
  }

  Widget _buildClientInfo() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      color: AppColors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            children: [
              Text(
                AppStrings.selectedClient,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: constraints.maxWidth > 600 ? 16 : 14,
                    ),
              ),
              const SizedBox(width: AppDimensions.paddingM),
              Expanded(
                child: Text(
                  AppStrings.noClientSelected,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: constraints.maxWidth > 600 ? 14 : 12,
                      ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCatalogSection() {
    return Card(
      margin: const EdgeInsets.all(AppDimensions.paddingM),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del catálogo
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppDimensions.borderRadiusL),
                topRight: Radius.circular(AppDimensions.borderRadiusL),
              ),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.inventory,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: AppDimensions.paddingS),
                Text(
                  AppStrings.catalog,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                ),
                const Spacer(),
                BlocBuilder<ProductBloc, ProductState>(
                  builder: (context, state) {
                    if (state is ProductLoaded) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.paddingM,
                          vertical: AppDimensions.paddingS,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(
                              AppDimensions.borderRadiusL),
                        ),
                        child: Text(
                          '${state.products.length} productos',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),

          // Barra de búsqueda integrada
          _buildIntegratedSearchBar(),

          // Tabs de categorías integradas
          _buildIntegratedCategoryTabs(),

          // Grid de productos
          Expanded(
            child: _buildProductGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildIntegratedSearchBar() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: EnhancedSearchBar(
        searchController: _searchController,
        onSearchChanged: (query) {
          setState(() {});
          context.read<ProductBloc>().add(SearchProducts(query));
        },
        onClearSearch: () {
          _searchController.clear();
          context.read<ProductBloc>().add(const SearchProducts(''));
          setState(() {});
        },
      ),
    );
  }

  Widget _buildIntegratedCategoryTabs() {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        if (state is ProductLoaded) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: CategoryTabs(
              categories: state.categories,
              selectedCategory: state.selectedCategory,
              onCategorySelected: (category) {
                _searchController.clear();
                context
                    .read<ProductBloc>()
                    .add(LoadProductsByCategory(category));
                setState(() {});
              },
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildProductGrid() {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        if (state is ProductLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: AppDimensions.paddingM),
                Text('Cargando productos...'),
              ],
            ),
          );
        } else if (state is ProductLoaded) {
          return LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount =
                  _calculateCrossAxisCount(constraints.maxWidth);

              return ProductGrid(
                products: state.products,
                crossAxisCount: crossAxisCount,
                onProductTap: (product, quantity, isDeleteMode) {
                  if (isDeleteMode) {
                    final cartBloc = context.read<CartBloc>();
                    final quantityInCart =
                        cartBloc.getProductQuantityInCart(product.id);

                    if (quantityInCart >= quantity) {
                      cartBloc
                          .add(RemoveQuantityFromCart(product.id, quantity));
                    } else if (quantityInCart > 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Solo hay $quantityInCart unidades de ${product.name} en el carrito. No se puede eliminar $quantity.',
                          ),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: AppColors.warning,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('${product.name} no está en el carrito'),
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: AppColors.info,
                        ),
                      );
                    }
                  } else {
                    context
                        .read<CartBloc>()
                        .add(AddToCart(product, quantity: quantity));
                  }

                  context.read<UiBloc>().add(ResetQuantity());
                },
              );
            },
          );
        } else if (state is ProductError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.cloud_off,
                    size: 64,
                    color: AppColors.warning,
                  ),
                  const SizedBox(height: AppDimensions.paddingM),
                  Text(
                    'Problema de conexión',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.warning,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimensions.paddingS),
                  Text(
                    state.message,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimensions.paddingL),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<ProductBloc>().add(LoadProducts());
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildActionButtons() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ActionButtons(
          isCompact: constraints.maxWidth < 1000,
          onReportPressed: () {
            showDialog(
              context: context,
              builder: (context) => BlocProvider(
                create: (_) => di.sl<ReportsBloc>(),
                child: const ReportsDialog(),
              ),
            );
          },
          onSaveOrderPressed: () {
            final cartState = context.read<CartBloc>().state;
            if (cartState is CartLoaded && cartState.items.isNotEmpty) {
              showDialog(
                context: context,
                builder: (context) => SaveOrderDialog(
                  cartItems: cartState.items,
                  total: cartState.total,
                  clientName: null,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('El carrito está vacío'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          onResumePressed: () async {
            final result = await showDialog<SavedOrder>(
              context: context,
              builder: (context) => const LoadSavedOrdersDialog(),
            );

            if (result != null) {
              context.read<CartBloc>().add(ClearCart());

              for (final item in result.items) {
                context
                    .read<CartBloc>()
                    .add(AddToCart(item.product, quantity: item.quantity));
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Pedido "${result.name}" cargado exitosamente'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          onSelectClientPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content:
                      Text('Función de selección de cliente no implementada')),
            );
          },
          onAddClientPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Función de agregar cliente no implementada')),
            );
          },
          onConfirmPressed: () {
            final cartState = context.read<CartBloc>().state;
            if (cartState is CartLoaded && cartState.items.isNotEmpty) {
              _showConfirmDialog(cartState.total);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('El carrito está vacío')),
              );
            }
          },
        );
      },
    );
  }

  int _calculateCrossAxisCount(double width) {
    if (width > 1400) return 5;
    if (width > 1100) return 4;
    if (width > 800) return 3;
    if (width > 500) return 2;
    return 1;
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cerrar Sesión'),
          content: const Text('¿Estás seguro que deseas cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<AuthBloc>().add(LogoutRequested());
                context.go(RoutePaths.login);
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  void _showConfirmDialog(double total) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Venta'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Total a cobrar: \$${total.toStringAsFixed(2)}'),
              const SizedBox(height: 16),
              const Text('¿Deseas procesar esta venta?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();

                final cartState = context.read<CartBloc>().state as CartLoaded;

                // Guardar la orden completada
                try {
                  final completeOrderUsecase = di.sl<CompleteOrderUsecase>();
                  await completeOrderUsecase(
                    items: cartState.items,
                    total: cartState.total,
                    clientName:
                        null, // Aquí podrías pasar el cliente seleccionado
                    cashierName: 'Brayan', // Obtener del usuario logueado
                  );
                } catch (e) {
                  print('Error al guardar orden completada: $e');
                }

                context.read<CartBloc>().add(ClearCart());
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Venta procesada exitosamente'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }
}
