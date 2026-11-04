import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/core/utils/extensions.dart';
import 'package:punto_venta_app/features/auth/prensetation/bloc/auth_bloc.dart';
import 'package:punto_venta_app/features/auth/prensetation/bloc/auth_state.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/fetch_pdv_config_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/fetch_ticket_config_usecase.dart';
import 'package:punto_venta_app/core/utils/app_logger.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_state.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/clients/clients_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/clients/clients_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/clients/clients_state.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/payment_methods/payment_methods_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/payment_methods/payment_methods_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/product/product_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/product/product_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_state.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/app/pos_app_bar.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/cart_checkout_side_effects.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/cart_empty_widget.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/cart_panel.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/cart_panel_header.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/cart_log_item_widget.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/cart_summary_widget.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/confirmation_panel.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/scanner_mode_content_widget.dart';
import 'package:punto_venta_app/core/widgets/scroll_bottom_extension.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/catalog/catalog_card.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/client/client_info_bar.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/product/integrated_search_bar.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/product/category_tabs_section.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/product/product_grid_section.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/product/search_bar.dart/search_weight_helper.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/product/search_bar.dart/weight_input_dialog.dart';
import 'package:punto_venta_app/features/pos/domain/entities/cart_log_entry.dart';
import 'package:punto_venta_app/features/pos/domain/entities/product.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cash_register/cash_register_cubit.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cash_register/cash_register_state.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cash_register/closed_register_view.dart';
import 'package:punto_venta_app/features/customer_display/presentation/customer_display_binder.dart';
import 'package:punto_venta_app/features/pos/presentation/utils/pvs_bootstrap.dart';
import 'package:punto_venta_app/injection_container.dart' as di;

class PosMainPage extends StatefulWidget {
  const PosMainPage({super.key});

  @override
  State<PosMainPage> createState() => _PosMainPageState();
}

class _PosMainPageState extends State<PosMainPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _catalogLogScrollController = ScrollController();
  final GlobalKey<ScaffoldMessengerState> _posMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  int _lastLogLength = 0;

  @override
  void initState() {
    super.initState();

    context.read<PaymentMethodsBloc>().add(LoadPaymentMethods());

    if (context.read<CartBloc>().state is! CartLoaded) {
      context.read<CartBloc>().add(ClearCart());
    }

    _initPdvConfigAndDefaultClient();
    _fetchAppConfig();
    bootstrapPvsCredentials();

    context.read<ProductBloc>().add(const LoadProducts());
  }

  Future<void> _initPdvConfigAndDefaultClient() async {
    AppLogger.info(
      'PosMainPage: init PDV config — log file=${AppLogger.logPath}',
    );
    try {
      final config = await di.sl<FetchPdvConfigUsecase>()();
      AppLogger.info(
        'PosMainPage: PDV sync ok pdvId=${config.pdvId} '
        'branchId=${config.branchId} → LoadDefaultClient',
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'PosMainPage: PDV sync failed, LoadDefaultClient con cache si hay',
        e,
        stackTrace,
      );
    }

    if (!mounted) return;
    context.read<ClientsBloc>().add(LoadDefaultClientEvent());
  }

  Future<void> _fetchAppConfig() async {
    try {
      final fetchAppConfigUsecase = di.sl<FetchTicketConfigUsecase>();
      await fetchAppConfigUsecase();
    } catch (e) {
      print('⚠️ No se pudo obtener configuración de sucursal: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _catalogLogScrollController.dispose();
    super.dispose();
  }

  CartLogEntry? _lastLogEntry(List<CartLogEntry> log) {
    if (log.isEmpty) return null;
    return log.last;
  }

  void _openConfirmation(BuildContext context, CartState state) {
    if (state is! CartLoaded || state.items.isEmpty) return;
    final uiState = context.read<UiBloc>().state;
    final isBarcodeMode =
        uiState is UiLoaded ? uiState.isBarcodeSearchEnabled : true;
    if (!isBarcodeMode) {
      context.read<UiBloc>().add(ToggleBarcodeSearch());
    }
    context.read<UiBloc>().add(OpenConfirmationPanel());
  }

  Future<void> _showManualCartSheet(BuildContext context) async {
    final cartBloc = context.read<CartBloc>();
    final uiBloc = context.read<UiBloc>();
    final cashCubit = context.read<CashRegisterCubit>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return MultiBlocProvider(
          providers: [
            BlocProvider.value(value: cartBloc),
            BlocProvider.value(value: uiBloc),
            BlocProvider.value(value: cashCubit),
          ],
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.75,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return Column(
                children: [
                  const CartPanelHeader(),
                  Expanded(
                    child: BlocBuilder<CartBloc, CartState>(
                      builder: (context, state) {
                        if (state is! CartLoaded || state.log.isEmpty) {
                          return const CartEmptyWidget();
                        }
                        return ListView.builder(
                          controller: scrollController,
                          padding:
                              const EdgeInsets.all(AppDimensions.paddingS),
                          itemCount: state.log.length,
                          itemBuilder: (context, index) {
                            return CartLogItemWidget(entry: state.log[index]);
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomerDisplayBinder(
      child: PopScope(
        canPop: false,
        child: BlocListener<ClientsBloc, ClientsState>(
          listenWhen: (previous, current) {
            if (previous is ClientsLoaded && current is ClientsLoaded) {
              return previous.selectedClient?.id != current.selectedClient?.id;
            }
            if (previous is! ClientsLoaded && current is ClientsLoaded) {
              return true;
            }
            return false;
          },
          listener: (context, state) {
            if (state is ClientsLoaded) {
              final priceListId = state.selectedClient?.listId;
              context
                  .read<ProductBloc>()
                  .add(LoadProducts(priceListId: priceListId));
            }
          },
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              final user =
                  authState is AuthAuthenticated ? authState.user : null;

              return Scaffold(
                resizeToAvoidBottomInset: true,
                body: CartCheckoutSideEffects(
                  child: BlocBuilder<UiBloc, UiState>(
                    builder: (context, uiState) {
                      final isMpQrActive =
                          uiState is UiLoaded && uiState.isMpQrActive;
                      final showConfirmation = uiState is UiLoaded &&
                          uiState.showConfirmationPanel;

                      return ScaffoldMessenger(
                        key: _posMessengerKey,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final spec =
                                LayoutSpec.fromWidth(constraints.maxWidth);
                            final shell = spec.useWidePosShell
                                ? _buildExpandedShell(
                                    context,
                                    user: user,
                                    isMpQrActive: isMpQrActive,
                                  )
                                : _buildCompactShell(
                                    context,
                                    user: user,
                                    isMpQrActive: isMpQrActive,
                                    uiState: uiState,
                                  );

                            return Stack(
                              children: [
                                shell,
                                if (showConfirmation && !spec.useWidePosShell)
                                  Positioned.fill(
                                    child: Material(
                                      color: Theme.of(context)
                                          .scaffoldBackgroundColor,
                                      child: SafeArea(
                                        child: ConfirmationPanel(
                                          onClose: () {
                                            context.read<UiBloc>().add(
                                                CloseConfirmationPanel());
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedShell(
    BuildContext context, {
    required dynamic user,
    required bool isMpQrActive,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Scaffold(
            resizeToAvoidBottomInset: true,
            body: Stack(
              children: [
                Column(
                  children: [
                    PosAppBar(user: user),
                    const ClientInfoBar(),
                    Expanded(child: _buildCatalogBody(context)),
                  ],
                ),
                if (isMpQrActive)
                  Positioned.fill(
                    child: AbsorbPointer(
                      child: ColoredBox(
                        color: Colors.black.withValues(alpha: 0.28),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const Expanded(
          flex: 1,
          child: CartPanel(attachSideEffects: false),
        ),
      ],
    );
  }

  Widget _buildCompactShell(
    BuildContext context, {
    required dynamic user,
    required bool isMpQrActive,
    required UiState uiState,
  }) {
    final isBarcodeMode =
        uiState is UiLoaded ? uiState.isBarcodeSearchEnabled : true;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Column(
            children: [
              PosAppBar(user: user, showMenuButton: true),
              const ClientInfoBar(),
              Expanded(child: _buildCatalogBody(context)),
              if (isBarcodeMode) _buildCompactScanPreviewBand(),
              _buildCompactStickyBar(context, isBarcodeMode: isBarcodeMode),
            ],
          ),
          if (isMpQrActive)
            Positioned.fill(
              child: AbsorbPointer(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.28),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompactScanPreviewBand() {
    return Material(
      elevation: 2,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          final lastEntry =
              state is CartLoaded ? _lastLogEntry(state.log) : null;
          return ScannerModeContent(
            key: ValueKey(lastEntry?.id ?? 'empty-dense'),
            lastEntry: lastEntry,
            dense: true,
          );
        },
      ),
    );
  }

  Widget _buildCompactStickyBar(
    BuildContext context, {
    required bool isBarcodeMode,
  }) {
    return Material(
      elevation: 8,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        top: false,
        child: BlocBuilder<CartBloc, CartState>(
          builder: (context, state) {
            final total = state is CartLoaded ? state.totalConIva : 0.0;
            final subtotal = state is CartLoaded ? state.subtotal : 0.0;
            final totalIva = state is CartLoaded ? state.totalIva : 0.0;
            final itemCount =
                state is CartLoaded ? state.items.length : 0;

            return BlocBuilder<UiBloc, UiState>(
              builder: (context, uiState) {
                final cartMode =
                    uiState is UiLoaded ? uiState.cartMode : CartMode.sale;

                return BlocBuilder<CashRegisterCubit, CashRegisterState>(
                  builder: (context, registerState) {
                    final isConfirmEnabled =
                        registerState is CashRegisterLoaded &&
                            registerState.status.isOpen;

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isBarcodeMode)
                            InkWell(
                              onTap: () => _showManualCartSheet(context),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 6, horizontal: 4),
                                child: Row(
                                  children: [
                                    const Icon(Icons.receipt_long, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        itemCount == 0
                                            ? 'Ver pedido'
                                            : 'Ver pedido ($itemCount)',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      total.formatToCurrency(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const Icon(Icons.keyboard_arrow_up),
                                  ],
                                ),
                              ),
                            ),
                          if (isBarcodeMode)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  const Text(
                                    'Total',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  const Spacer(),
                                  Text(
                                    total.formatToCurrency(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          CartSummary(
                            subtotal: subtotal,
                            totalIva: totalIva,
                            totalConIva: total,
                            cartMode: cartMode,
                            isConfirmEnabled: isConfirmEnabled,
                            onConfirm: () =>
                                _openConfirmation(context, state),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildCatalogBody(BuildContext context) {
    return BlocBuilder<CashRegisterCubit, CashRegisterState>(
      builder: (context, registerState) {
        if (registerState is CashRegisterLoading) {
          final currentStatus =
              context.read<CashRegisterCubit>().currentStatus;
          if (currentStatus == null) {
            return const Center(child: CircularProgressIndicator());
          }
        }

        final currentStatus = registerState is CashRegisterLoaded
            ? registerState.status
            : (registerState is CashRegisterError
                ? registerState.lastStatus
                : context.read<CashRegisterCubit>().currentStatus);

        final isRegisterOpen = currentStatus?.isOpen ?? false;

        if (!isRegisterOpen) {
          return const ClosedRegisterView();
        }

        return BlocBuilder<UiBloc, UiState>(
          builder: (context, catalogUiState) {
            final isBarcodeMode = catalogUiState is UiLoaded
                ? catalogUiState.isBarcodeSearchEnabled
                : true;

            return CatalogCard(
              searchBar: IntegratedSearchBar(
                controller: _searchController,
                autofocus: false,
                onSearchChanged: (query) {
                  setState(() {});
                  context.read<ProductBloc>().add(SearchProducts(query));
                },
                onClearSearch: () {
                  _searchController.clear();
                  context
                      .read<ProductBloc>()
                      .add(const SearchProducts(''));
                  setState(() {});
                },
              ),
              categoryTabs: isBarcodeMode
                  ? const SizedBox.shrink()
                  : CategoryTabsSection(
                      onCategorySelected: (_) {},
                      onClearSearch: () {
                        _searchController.clear();
                        context
                            .read<ProductBloc>()
                            .add(const SearchProducts(''));
                      },
                    ),
              productGrid: isBarcodeMode
                  ? _buildCartLogsInCatalog()
                  : ProductGridSection(
                      onProductTap: (product, quantity, isDeleteMode) async {
                        await _handleProductTap(
                          product: product,
                          quantity: quantity,
                          isDeleteMode: isDeleteMode,
                        );
                      },
                    ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleProductTap({
    required Product product,
    required int quantity,
    required bool isDeleteMode,
  }) async {
    if (isProductWeighted(product)) {
      final manualWeight = await showWeightInputDialog(
        context,
        product: product,
        isDeleteMode: isDeleteMode,
      );

      if (!mounted) return;

      if (manualWeight == null || manualWeight <= 0) {
        context.read<UiBloc>().add(ResetQuantity());
        return;
      }

      final lineTotal = calculateWeightedLineTotal(product, manualWeight);

      if (isDeleteMode) {
        context.read<CartBloc>().add(RemoveQuantityFromCart(
              product.id.toString(),
              1,
              isWeighted: true,
              weightKg: manualWeight,
              pricePerKg: lineTotal,
            ));
      } else if (product.price != null) {
        context.read<CartBloc>().add(AddToCart(
              product,
              quantity: 1,
              isWeighted: true,
              weightKg: manualWeight,
              pricePerKg: lineTotal,
            ));
      }

      context.read<UiBloc>().add(ResetQuantity());
      return;
    }

    if (isDeleteMode) {
      final cartBloc = context.read<CartBloc>();
      final quantityInCart =
          cartBloc.getProductQuantityInCart(product.id.toString());

      if (quantityInCart >= quantity) {
        cartBloc.add(RemoveQuantityFromCart(product.id.toString(), quantity));
      } else if (quantityInCart > 0) {
        _posMessengerKey.currentState?.showSnackBar(
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
        _posMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('${product.name} no está en el carrito'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.info,
          ),
        );
      }
    } else if (product.price != null) {
      context.read<CartBloc>().add(AddToCart(product, quantity: quantity));
    }

    context.read<UiBloc>().add(ResetQuantity());
  }

  Widget _buildCartLogsInCatalog() {
    return BlocConsumer<CartBloc, CartState>(
      listener: (context, state) {
        if (state is CartLoaded) {
          if (state.log.length != _lastLogLength) {
            _lastLogLength = state.log.length;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_catalogLogScrollController.hasClients) {
                _catalogLogScrollController.scrollToBottom();
              }
            });
          }
        } else {
          _lastLogLength = 0;
        }
      },
      builder: (context, state) {
        if (state is CartLoaded) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_catalogLogScrollController.hasClients &&
                state.log.isNotEmpty) {
              _catalogLogScrollController.scrollToBottom();
            }
          });

          if (state.log.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Escanea productos para agregarlos',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _catalogLogScrollController,
                    itemCount: state.log.length,
                    itemBuilder: (context, index) {
                      final entry = state.log[index];
                      return CartLogItemWidget(entry: entry);
                    },
                  ),
                ),
              ],
            ),
          );
        }
        return const Center(
          child: Text('No hay items en el carrito'),
        );
      },
    );
  }
}
