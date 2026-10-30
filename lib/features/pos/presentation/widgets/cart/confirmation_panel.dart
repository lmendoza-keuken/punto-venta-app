import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_state.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/checkout/checkout_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/checkout/checkout_state.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/checkout_confirmation/checkout_confirmation_cubit.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/checkout_confirmation/checkout_confirmation_state.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/clients/clients_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/payment_methods/payment_methods_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/payment_methods/payment_methods_state.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/confirmation/dispose_confirmation/dispose_confirmation_view.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/confirmation/return_confirmation/return_confirmation_view.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_state.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/confirmation/checkout_confirmation/checkout_confirmation_view.dart';
import 'package:punto_venta_app/injection_container.dart' as di;

class ConfirmationPanel extends StatefulWidget {
  final VoidCallback onClose;

  const ConfirmationPanel({
    super.key,
    required this.onClose,
  });

  @override
  State<ConfirmationPanel> createState() => _ConfirmationPanelState();
}

class _ConfirmationPanelState extends State<ConfirmationPanel> {
  String _titleForMode(CartMode mode) {
    switch (mode) {
      case CartMode.returnMode:
        return 'Confirmar Devolución';
      case CartMode.disposeMode:
        return 'Confirmar Descarte';
      case CartMode.sale:
        return 'Confirmar Pago';
    }
  }

  String _processingLabel(CartMode mode) {
    switch (mode) {
      case CartMode.returnMode:
        return 'Procesando devolución...';
      case CartMode.disposeMode:
        return 'Procesando descarte...';
      case CartMode.sale:
        return 'Procesando venta...';
    }
  }

  Color _confirmColor(CartMode mode) {
    switch (mode) {
      case CartMode.returnMode:
        return AppColors.warning;
      case CartMode.disposeMode:
        return Colors.brown.shade600;
      case CartMode.sale:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pmState = context.read<PaymentMethodsBloc>().state;
    final defaultPaymentMethod =
        pmState is PaymentMethodsLoaded ? pmState.selectedPaymentMethod : null;

    final uiState = context.read<UiBloc>().state;
    final cartMode = uiState is UiLoaded ? uiState.cartMode : CartMode.sale;

    return BlocProvider(
      create: (context) => CheckoutConfirmationCubit(
        fetchReturnReasonsUsecase: di.sl(),
        fetchDisposeReasonsUsecase: di.sl(),
        calculateOrderTaxesUseCase: di.sl(),
        cartBloc: context.read<CartBloc>(),
        clientsBloc: context.read<ClientsBloc>(),
      )..load(defaultPaymentMethod, cartMode: cartMode),
      child: BlocBuilder<CartBloc, CartState>(
        builder: (context, cartState) {
          if (cartState is! CartLoaded) {
            return const SizedBox.shrink();
          }

          final uiState = context.watch<UiBloc>().state;
          final cartMode =
              uiState is UiLoaded ? uiState.cartMode : CartMode.sale;

          return BlocBuilder<CheckoutConfirmationCubit,
              CheckoutConfirmationState>(
            builder: (context, confirmationState) {
              final totalAmount = confirmationState.totalAmount;

              return BlocBuilder<CheckoutBloc, CheckoutState>(
                builder: (context, checkoutState) {
                  final isProcessing = checkoutState is CheckoutProcessing;

                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.paddingM,
                            vertical: AppDimensions.paddingXS),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade200),
                          ),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back),
                              onPressed: isProcessing ? null : _handleClose,
                            ),
                            const SizedBox(width: AppDimensions.paddingS),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _titleForMode(cartMode),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  if (cartMode == CartMode.sale &&
                                      confirmationState.activeBranchName !=
                                          null) ...[
                                    const SizedBox(height: 2),
                                    if (confirmationState
                                            .allowedBranches.length >
                                        1)
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.business_rounded,
                                            size: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                          const SizedBox(width: 4),
                                          DropdownButtonHideUnderline(
                                            child: DropdownButton<int>(
                                              value: confirmationState
                                                  .activeBranchId,
                                              isDense: true,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade700,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              icon: Icon(
                                                Icons.arrow_drop_down_rounded,
                                                size: 16,
                                                color: Colors.grey.shade600,
                                              ),
                                              items: confirmationState
                                                  .allowedBranches
                                                  .map((branch) {
                                                return DropdownMenuItem<int>(
                                                  value: branch.id,
                                                  child: Text(branch.name),
                                                );
                                              }).toList(),
                                              onChanged: (branchId) {
                                                if (branchId != null) {
                                                  context
                                                      .read<
                                                          CheckoutConfirmationCubit>()
                                                      .selectBranch(branchId);
                                                }
                                              },
                                            ),
                                          ),
                                        ],
                                      )
                                    else
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.business_rounded,
                                            size: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Sucursal: ${confirmationState.activeBranchName}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(AppDimensions.paddingL),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (cartMode == CartMode.returnMode)
                                ReturnConfirmationView(
                                  totalAmount: totalAmount,
                                  isLoadingReasons: confirmationState.isLoading,
                                  returnReasons:
                                      confirmationState.returnReasons,
                                  selectedReturnReasonId:
                                      confirmationState.selectedReturnReasonId,
                                  onReturnReasonChanged: (id) {
                                    if (id != null) {
                                      context
                                          .read<CheckoutConfirmationCubit>()
                                          .selectReturnReason(id);
                                    }
                                  },
                                )
                              else if (cartMode == CartMode.disposeMode)
                                DisposeConfirmationView(
                                  totalAmount: totalAmount,
                                  isLoadingReasons: confirmationState.isLoading,
                                  disposeReasons:
                                      confirmationState.disposeReasons,
                                  selectedDisposeReasonId: confirmationState
                                      .selectedDisposeReasonId,
                                  onDisposeReasonChanged: (id) {
                                    if (id != null) {
                                      context
                                          .read<CheckoutConfirmationCubit>()
                                          .selectDisposeReason(id);
                                    }
                                  },
                                )
                              else
                                CheckoutConfirmationView(
                                  totalAmount: totalAmount,
                                  iibbAmount: confirmationState.iibbAmount,
                                  vatPerceptionAmount:
                                      confirmationState.vatPerceptionAmount,
                                  internalTaxAmount:
                                      confirmationState.internalTaxAmount,
                                  cartSubtotal: cartState.subtotal,
                                  cartTotalIva: cartState.totalIva,
                                ),
                              if (isProcessing) ...[
                                const SizedBox(height: 24),
                                Container(
                                  padding: const EdgeInsets.all(
                                      AppDimensions.paddingM),
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.info.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        _processingLabel(cartMode),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.paddingL,
                            vertical: AppDimensions.paddingS),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.grey.shade200),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: SizedBox(
                                height: AppDimensions.buttonHeightS,
                                child: ElevatedButton(
                                  onPressed: isProcessing ||
                                          !confirmationState.isValid(cartMode)
                                      ? null
                                      : () {
                                          switch (cartMode) {
                                            case CartMode.returnMode:
                                              _confirmReturn(context);
                                            case CartMode.disposeMode:
                                              _confirmDispose(context);
                                            case CartMode.sale:
                                              _confirmSale(context);
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _confirmColor(cartMode),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: isProcessing
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        )
                                      : const Text(
                                          'Confirmar',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppDimensions.paddingM),
                            Expanded(
                              flex: 1,
                              child: SizedBox(
                                height: AppDimensions.buttonHeightS,
                                child: ElevatedButton(
                                  onPressed: isProcessing ? null : _handleClose,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.error,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Cancelar',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _confirmSale(BuildContext context) {
    final paymentMethodsState = context.read<PaymentMethodsBloc>().state;
    final selectedPaymentMethod = paymentMethodsState is PaymentMethodsLoaded
        ? paymentMethodsState.selectedPaymentMethod
        : null;

    final event =
        context.read<CheckoutConfirmationCubit>().buildProcessSaleEvent(
              fallbackPaymentMethod: selectedPaymentMethod,
            );
    context.read<CheckoutBloc>().add(event);
  }

  void _confirmReturn(BuildContext context) {
    final event =
        context.read<CheckoutConfirmationCubit>().buildConfirmReturnEvent();
    context.read<CheckoutBloc>().add(event);
  }

  void _confirmDispose(BuildContext context) {
    final event = context
        .read<CheckoutConfirmationCubit>()
        .buildConfirmStockDisposeEvent();
    context.read<CheckoutBloc>().add(event);
  }

  void _handleClose() {
    widget.onClose();
  }
}
