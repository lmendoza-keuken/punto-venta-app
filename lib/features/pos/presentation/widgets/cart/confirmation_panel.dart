import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_state.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/checkout/checkout_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/checkout/checkout_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/checkout/checkout_state.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/checkout_confirmation/checkout_confirmation_cubit.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/checkout_confirmation/checkout_confirmation_state.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/clients/clients_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/clients/clients_state.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/payment_methods/payment_methods_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/payment_methods/payment_methods_state.dart';
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
  @override
  Widget build(BuildContext context) {
    final pmState = context.read<PaymentMethodsBloc>().state;
    final defaultPaymentMethod =
        pmState is PaymentMethodsLoaded ? pmState.selectedPaymentMethod : null;

    return BlocProvider(
      create: (context) => CheckoutConfirmationCubit(
        fetchReturnReasonsUsecase: di.sl(),
        pdvLocalDataSource: di.sl(),
        branchLocalDataSource: di.sl(),
        vatCategoryLocalDataSource: di.sl(),
        cartBloc: context.read<CartBloc>(),
        clientsBloc: context.read<ClientsBloc>(),
      )..load(defaultPaymentMethod),
      child: BlocBuilder<CartBloc, CartState>(
        builder: (context, cartState) {
          if (cartState is! CartLoaded) {
            return const SizedBox.shrink();
          }

          final uiState = context.watch<UiBloc>().state;
          final isReturnMode =
              uiState is UiLoaded ? uiState.isReturnMode : false;

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
                              child: Text(
                                isReturnMode
                                    ? 'Confirmar Devolución'
                                    : 'Confirmar Pago',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
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
                              if (isReturnMode)
                                // Vista de devolución
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
                              else
                                // Vista de cobro
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
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        'Procesando venta...',
                                        style: TextStyle(
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
                      // Botones de acción
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
                                          !confirmationState
                                              .isValid(isReturnMode)
                                      ? null
                                      : () {
                                          if (isReturnMode) {
                                            _confirmReturn(context, cartState,
                                                confirmationState);
                                          } else {
                                            _confirmSale(context, cartState,
                                                confirmationState);
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isReturnMode
                                        ? AppColors.warning
                                        : AppColors.success,
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
                                            fontWeight: FontWeight.bold,
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

  // Función para confirmar la venta
  void _confirmSale(
    BuildContext context,
    CartLoaded cartState,
    CheckoutConfirmationState confirmationState,
  ) {
    final clientsState = context.read<ClientsBloc>().state;
    final selectedClient =
        clientsState is ClientsLoaded ? clientsState.selectedClient : null;

    final paymentMethodsState = context.read<PaymentMethodsBloc>().state;
    final selectedPaymentMethod = paymentMethodsState is PaymentMethodsLoaded
        ? paymentMethodsState.selectedPaymentMethod
        : null;

    context.read<CheckoutBloc>().add(
          ProcessSale(
            items: cartState.items,
            logItems: cartState.log,
            total: cartState.total,
            totalIva: cartState.totalIva,
            subtotal: cartState.subtotal,
            client: selectedClient,
            paymentMethod: confirmationState.selectedPayments.isNotEmpty
                ? confirmationState.selectedPayments.first
                : selectedPaymentMethod,
            paymentMethods: confirmationState.selectedPayments.isNotEmpty
                ? confirmationState.selectedPayments
                : null,
            receivedAmount: confirmationState.receivedAmount,
            change: confirmationState.change,
          ),
        );
  }

  // funcion para confirmar la devolucion
  void _confirmReturn(
    BuildContext context,
    CartLoaded cartState,
    CheckoutConfirmationState confirmationState,
  ) {
    if (confirmationState.selectedReturnReasonId == null) return;

    context.read<CheckoutBloc>().add(
          ConfirmReturn(
            reasonId: confirmationState.selectedReturnReasonId!,
            items: cartState.items,
            logItems: cartState.log,
          ),
        );
  }

  // Función para manejar el cierre del panel
  void _handleClose() {
    widget.onClose();
  }
}
