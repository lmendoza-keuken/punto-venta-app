import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/themes/theme_cubit.dart';
import 'package:punto_venta_app/core/widgets/scroll_bottom_extension.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_state.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/cart_empty_widget.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/cart_log_item_widget.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/cart_panel_header.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/cart_summary_widget.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/confirmation_panel.dart';
import 'package:punto_venta_app/features/pos/presentation/utils/internal_tax_calculator.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../bloc/cart/cart_bloc.dart';
import '../../bloc/cart/cart_state.dart';

class CartPanel extends StatefulWidget {
  const CartPanel({super.key});

  @override
  State<CartPanel> createState() => _CartPanelState();
}

class _CartPanelState extends State<CartPanel> {
  final ScrollController _scrollController = ScrollController();
  int _lastLogLength = 0;
  bool _showConfirmation = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, mode) {
        final isDark = mode == ThemeMode.dark;
        final backgroundColor = isDark
            ? AppColors.sidebarDarkBackground
            : AppColors.sidebarLightBackground;
        final borderColor = isDark
            ? AppColors.sidebarDarkDivider
            : AppColors.sidebarLightDivider;

        return LayoutBuilder(
          builder: (context, constraints) {
            final panelWidth = constraints.maxWidth;
            return Stack(
              children: [
                // Panel principal del carrito
                Container(
                  decoration: BoxDecoration(
                    color: backgroundColor,
                  ),
                  child: Column(
                    children: [
                      const CartPanelHeader(),
                      Expanded(
                        child: BlocBuilder<UiBloc, UiState>(
                          builder: (context, uiState) {
                            final isBarcodeMode = uiState is UiLoaded
                                ? uiState.isBarcodeSearchEnabled
                                : true;
                            final isReturnMode = uiState is UiLoaded
                                ? uiState.isReturnMode
                                : false;

                            return BlocConsumer<CartBloc, CartState>(
                              listener: (context, state) {
                                if (state is CartLoaded && !isBarcodeMode) {
                                  if (state.log.length != _lastLogLength) {
                                    _lastLogLength = state.log.length;
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                      if (_scrollController.hasClients) {
                                        _scrollController.scrollToBottom();
                                      }
                                    });
                                  }
                                } else {
                                  _lastLogLength = 0;
                                }
                              },
                              builder: (context, state) {
                                if (state is CartLoaded) {
                                  if (!isBarcodeMode && state.log.isNotEmpty) {
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                      if (_scrollController.hasClients) {
                                        _scrollController.scrollToBottom();
                                      }
                                    });
                                  }
                                  final internalTaxResult =
                                      InternalTaxCalculator
                                          .calculateInternalTax(
                                    items: state.items,
                                  );
                                  final internalTax =
                                      internalTaxResult['total'] ?? 0.0;
                                  double subtotal = state.subtotal;
                                  double totalIva = state.totalIva;
                                  double totalConIva =
                                      subtotal + totalIva + internalTax;

                                  return Column(
                                    children: [
                                      // Área principal: logs o mensaje según el modo
                                      Expanded(
                                        child: isBarcodeMode
                                            ? Center(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.barcode_reader,
                                                      size: 64,
                                                      color:
                                                          Colors.grey.shade400,
                                                    ),
                                                    const SizedBox(height: 16),
                                                    Text(
                                                      'Modo escaneo de código de barras',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        color: Colors
                                                            .grey.shade600,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      'Ver historial en el área principal',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors
                                                            .grey.shade500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            : Padding(
                                                padding: const EdgeInsets.all(
                                                    AppDimensions.paddingS),
                                                child: state.log.isEmpty
                                                    ? const CartEmptyWidget()
                                                    : ListView.builder(
                                                        controller:
                                                            _scrollController,
                                                        itemCount:
                                                            state.log.length,
                                                        itemBuilder:
                                                            (context, index) {
                                                          final entry =
                                                              state.log[index];
                                                          return CartLogItemWidget(
                                                              entry: entry);
                                                        },
                                                      ),
                                              ),
                                      ),
                                      const Divider(height: 1),
                                      // monto, botones de cartPanel ( confirmar venta o devolucion)
                                      CartSummary(
                                        subtotal: subtotal,
                                        totalIva: totalIva,
                                        totalConIva: totalConIva,
                                        isReturnMode: isReturnMode,
                                        onClear: () {
                                          context
                                              .read<CartBloc>()
                                              .add(ClearCart());
                                        },
                                        onConfirm: () {
                                          if (state.items.isNotEmpty) {
                                            if (!isBarcodeMode) {
                                              context
                                                  .read<UiBloc>()
                                                  .add(ToggleBarcodeSearch());
                                            }
                                            // abre el showconfirmation panel
                                            setState(() {
                                              _showConfirmation = true;
                                            });
                                          }
                                        },
                                      ),
                                    ],
                                  );
                                }
                                return const CartEmptyWidget();
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Panel de confirmación expandido ( dependiendo de la var _showConfirmation)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  right: _showConfirmation ? 0 : -panelWidth,
                  top: 0,
                  bottom: 0,
                  width: panelWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      border: Border(
                        left: BorderSide(color: borderColor, width: 2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(-2, 0),
                        ),
                      ],
                    ),
                    child: ConfirmationPanel(
                      // desde el confirmation panel se pasa el onClose() (cierra el panel. deberia esperar un estado de ahi si cerrar y limpiar el (cartpanel. o el cliente default(en el pos) ) )
                      onClose: () {
                        setState(() {
                          _showConfirmation = false;
                        });
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
