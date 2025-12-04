import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/constants/app_string.dart';
import 'package:punto_venta_app/core/utils/extensions.dart';
import 'package:punto_venta_app/core/widgets/custom_butom.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_event.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/cart_log_item_widget.dart';
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

  //TODO: Mover a un Widget extensions
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final maxScroll = _scrollController.position.maxScrollExtent;
      if (maxScroll <= 0) return;
      try {
        _scrollController.animateTo(
          maxScroll,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } catch (_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppDimensions.cartPanelWidth,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(left: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          _buildCartHeader(context),
          Expanded(
            child: BlocConsumer<CartBloc, CartState>(
              listener: (context, state) {
                if (state is CartLoaded) {
                  if (state.log.length != _lastLogLength) {
                    _lastLogLength = state.log.length;
                    _scrollToBottom();
                  }
                } else {
                  _lastLogLength = 0;
                }
              },
              builder: (context, state) {
                if (state is CartLoaded) {
                  return Column(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(AppDimensions.paddingS),
                          child: state.log.isEmpty
                              ? _buildEmptyCart(context)
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
                      _buildSummary(context, state),
                    ],
                  );
                }

                return _buildEmptyCart(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          const Icon(Icons.shopping_cart, color: AppColors.primary),
          const SizedBox(width: AppDimensions.paddingS),
          Text(
            AppStrings.cartSummary,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(BuildContext context, CartLoaded state) {
    double subtotal = 0;
    double totalIva = 0;

    //TODO:  Cambiar para solo recibir los totales calculados
    for (var entry in state.log) {
      final precio = entry.item.product.precio ?? 0;
      final isWeighted = entry.item.isWeighted ?? false;
      final pricePerKg = entry.item.pricePerKg ?? 0.0;
      final cantidad = entry.item.quantity;
      final tasaIva = entry.item.iva / 100;

      if (isWeighted) {
        final precioTotal = pricePerKg;
        final ivaArticulo = precioTotal * tasaIva;
        subtotal += precioTotal;
        totalIva += ivaArticulo;
      } else {
        final precioTotal = precio * cantidad;
        final ivaArticulo = precioTotal * tasaIva;
        subtotal += precioTotal;
        totalIva += ivaArticulo;
      }
    }

    final totalConIva = subtotal + totalIva;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Column(
        children: [
          const SizedBox(height: AppDimensions.paddingS),
          // Subtotal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal:', style: Theme.of(context).textTheme.bodyMedium),
              Text(subtotal.formatToCurrency(),
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('IVA:', style: TextStyle(color: Colors.grey[700])),
              Text(totalIva.formatToCurrency(),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppStrings.total,
                  style: Theme.of(context).textTheme.bodyMedium),
              Text(totalConIva.formatToCurrency(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingM),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: AppStrings.empty,
                  onPressed: () {
                    context.read<CartBloc>().add(ClearCart());
                  },
                  backgroundColor: AppColors.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  //TODO:  Mover a un Widget aparte
  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined,
              size: 64, color: Colors.grey.shade400),
          const SizedBox(height: AppDimensions.paddingM),
          Text('Carrito vacío',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.grey.shade600)),
          const SizedBox(height: AppDimensions.paddingS),
          Text('Agrega productos para comenzar',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}
