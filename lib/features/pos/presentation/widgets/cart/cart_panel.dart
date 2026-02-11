import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(AppDimensions.paddingS),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusL),
      ),
      child: Column(
        children: [
          // titulo del panel
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
                          padding: const EdgeInsets.all(AppDimensions.paddingS),
                          child: state.log.isEmpty
                              // si el carrito está vacío
                              ? const CartEmptyWidget()
                              // lista de items en el carrito
                              : ListView.builder(
                                  controller: _scrollController,
                                  itemCount: state.log.length,
                                  itemBuilder: (context, index) {
                                    final entry = state.log[index];
                                    return CartLogItemWidget(entry: entry);
                                  },
                                ),
                        ),
                      ),
                      const Divider(height: 1),
                      // resumen del carrito
                      CartSummary(
                        subtotal: subtotal,
                        totalIva: totalIva,
                        totalConIva: totalConIva,
                        onClear: () {
                          context.read<CartBloc>().add(ClearCart());
                        },
                      ),
                    ],
                  );
                }
                // estado inicial o de error
                return const CartEmptyWidget();
              },
            ),
          ),
        ],
      ),
    );
  }
}
