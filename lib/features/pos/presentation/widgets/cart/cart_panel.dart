import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/themes/theme_cubit.dart';
import 'package:punto_venta_app/core/widgets/scroll_bottom_extension.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_event.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/cart_empty_widget.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/cart_log_item_widget.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/cart_panel_header.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/cart_summary_widget.dart';
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
                    child: BlocConsumer<CartBloc, CartState>(
                      listener: (context, state) {
                        if (state is CartLoaded) {
                          if (state.log.length != _lastLogLength) {
                            _lastLogLength = state.log.length;
                            _scrollController.scrollToBottom();
                          }
                        } else {
                          _lastLogLength = 0;
                        }
                      },
                      builder: (context, state) {
                        if (state is CartLoaded) {
                          double subtotal = state.subtotal;
                          double totalIva = state.totalIva;
                          double totalConIva = subtotal + totalIva;

                          return Column(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(
                                      AppDimensions.paddingS),
                                  child: state.log.isEmpty
                                      ? const CartEmptyWidget()
                                      : ListView.builder(
                                          controller: _scrollController,
                                          itemCount: state.log.length,
                                          itemBuilder: (context, index) {
                                            final entry = state.log[index];
                                            return CartLogItemWidget(
                                                entry: entry);
                                          },
                                        ),
                                ),
                              ),
                              const Divider(height: 1),
                              CartSummary(
                                subtotal: subtotal,
                                totalIva: totalIva,
                                totalConIva: totalConIva,
                                onClear: () {
                                  context.read<CartBloc>().add(ClearCart());
                                },
                                onConfirm: () {
                                  if (state.items.isNotEmpty) {
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
                    ),
                  ),
                ],
              ),
            ),

            // Panel de confirmación expandido
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              right: _showConfirmation ? 0 : -400,
              top: 0,
              bottom: 0,
              width: 400,
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
                child: _buildConfirmationPanel(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildConfirmationPanel() {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, state) {
        if (state is! CartLoaded) {
          return const SizedBox.shrink();
        }

        return Column(
          children: [
            // Header del panel de confirmación
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: () {
                      setState(() {
                        _showConfirmation = false;
                      });
                    },
                  ),
                  const SizedBox(width: AppDimensions.paddingS),
                  Text(
                    'Confirmar Pago',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),

            // Contenido del panel de confirmación
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resumen del Pedido',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: AppDimensions.paddingM),
                    
                    // Lista de items
                    ...state.log.map((entry) => Padding(
                          padding: const EdgeInsets.only(
                              bottom: AppDimensions.paddingS),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  entry.item.product.name,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                              Text(
                                'x${entry.item.quantity}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                            ],
                          ),
                        )),

                    const Divider(height: AppDimensions.paddingL),

                    // Totales
                    _buildTotalRow('Subtotal:', state.subtotal),
                    _buildTotalRow('IVA:', state.totalIva),
                    const Divider(),
                    _buildTotalRow(
                      'Total:',
                      state.subtotal + state.totalIva,
                      isTotal: true,
                    ),
                  ],
                ),
              ),
            ),

            // Botones de acción
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Aquí iría la lógica de confirmación final
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Pago confirmado'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                        context.read<CartBloc>().add(ClearCart());
                        setState(() {
                          _showConfirmation = false;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(
                            vertical: AppDimensions.paddingM),
                      ),
                      child: const Text(
                        'Confirmar Pago',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingS),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _showConfirmation = false;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: AppDimensions.paddingM),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                  fontSize: isTotal ? 18 : 14,
                ),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: isTotal ? 20 : 14,
                  color: isTotal ? AppColors.primary : null,
                ),
          ),
        ],
      ),
    );
  }
}
