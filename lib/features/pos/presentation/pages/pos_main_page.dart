import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos_flutter_app/core/constants/app_colors.dart';
import 'package:pos_flutter_app/core/constants/app_dimensions.dart';
import 'package:pos_flutter_app/core/constants/app_string.dart';
import 'package:pos_flutter_app/core/dialogs/logout_dialog.dart';
import 'package:pos_flutter_app/core/utils/utils.dart';
import 'package:pos_flutter_app/core/widgets/dynamic_date_time.dart';
import 'package:pos_flutter_app/features/pos/domain/entities/saved_order.dart';
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
import 'package:pos_flutter_app/features/pos/presentation/widgets/sale_confirm_dialog.dart';
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
            onPressed: () {
              showLogoutDialog(context);
            }),
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
      padding: const EdgeInsets.all(AppDimensions.paddingS),
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
                  calculateCrossAxisCount(constraints.maxWidth);

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
                  cartLogItems: cartState.log,
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
              context
                  .read<CartBloc>()
                  .add(ReplaceCart(items: result.items, log: result.logs));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content:
                        Text('Pedido "${result.name}" cargado exitosamente'),
                    backgroundColor: AppColors.success),
              );

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
              showConfirmDialog(cartState.total, context);
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
}
