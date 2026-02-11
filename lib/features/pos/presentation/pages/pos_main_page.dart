import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/features/auth/prensetation/bloc/auth_bloc.dart';
import 'package:punto_venta_app/features/auth/prensetation/bloc/auth_state.dart';
import 'package:punto_venta_app/features/pos/domain/entities/client.dart';
import 'package:punto_venta_app/features/pos/domain/entities/saved_order.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_state.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/clients/clients_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/clients/clients_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/product/product_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/product/product_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/reports/reports_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_event.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/app/pos_app_bar.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/product/action_buttons.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/dialogs/client/add_client_dialog.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/cart_panel.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/dialogs/order/load_saved_orders_dialog.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/dialogs/sale/payment_methods_dialog.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/dialogs/report/reports_dialog.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/dialogs/order/save_order_dialog.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/dialogs/client/select_client_dialog.dart';
import 'package:punto_venta_app/injection_container.dart' as di;
import 'package:punto_venta_app/features/pos/presentation/widgets/layout/responsive_two_column.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/catalog/catalog_card.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/client/client_info_bar.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/product/integrated_search_bar.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/product/category_tabs_section.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/product/product_grid_section.dart';

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
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final user = authState is AuthAuthenticated ? authState.user : null;

        return Scaffold(
          resizeToAvoidBottomInset: false,
          body: Row(
            children: [
              // Catálogo de productos
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    PosAppBar(user: user),
                    // const ClientInfoBar(),
                    Expanded(
                      child: CatalogCard(
                        // barra de búsqueda y categorías
                        searchBar: IntegratedSearchBar(
                          controller: _searchController,
                          autofocus: false,
                          onSearchChanged: (query) {
                            setState(() {});
                            context
                                .read<ProductBloc>()
                                .add(SearchProducts(query));
                          },
                          onClearSearch: () {
                            _searchController.clear();
                            context
                                .read<ProductBloc>()
                                .add(const SearchProducts(''));
                            setState(() {});
                          },
                        ),
                        categoryTabs: CategoryTabsSection(
                          onCategorySelected: (_) {},
                          onClearSearch: () {
                            _searchController.clear();
                            context
                                .read<ProductBloc>()
                                .add(const SearchProducts(''));
                          },
                        ),
                        // grilla de productos
                        productGrid: ProductGridSection(
                          onProductTap: (product, quantity, isDeleteMode) {
                            if (isDeleteMode) {
                              final cartBloc = context.read<CartBloc>();
                              final quantityInCart = cartBloc
                                  .getProductQuantityInCart(product.id.toString());

                              if (quantityInCart >= quantity) {
                                cartBloc.add(RemoveQuantityFromCart(
                                    product.id.toString(), quantity));
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
                                    content: Text(
                                        '${product.name} no está en el carrito'),
                                    duration: const Duration(seconds: 1),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: AppColors.info,
                                  ),
                                );
                              }
                            } else {
                              if (product.precio != null) {
                                context.read<CartBloc>().add(
                                    AddToCart(product, quantity: quantity));
                              }
                            }
                            context.read<UiBloc>().add(ResetQuantity());
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Panel de carrito
              Expanded(
                flex: 1,
                child: SizedBox(
                  width: 380,
                  child: const CartPanel(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
