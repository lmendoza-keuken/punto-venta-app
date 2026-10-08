import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/features/pos/domain/entities/payment_method.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/mercado_pago_repository.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/pvs_repository.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_state.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/checkout/checkout_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/checkout/checkout_state.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/checkout_confirmation/checkout_confirmation_cubit.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/checkout_confirmation/checkout_confirmation_state.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/clients/clients_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/mercado_pago_qr/mercado_pago_qr_state.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/payment_methods/payment_methods_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/payment_methods/payment_methods_state.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/pvs_qr/pvs_qr_state.dart';
import 'package:punto_venta_app/features/pos/presentation/utils/mercado_pago_qr_utils.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/confirmation/return_confirmation/return_confirmation_view.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_state.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/confirmation/checkout_confirmation/checkout_confirmation_view.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/mercado_pago/mercado_pago_qr_panel_view.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/pvs/pvs_qr_panel_view.dart';
import 'package:punto_venta_app/features/auth/data/datasources/auth_local_datasources.dart';
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
  /// Cuando no es null, el panel muestra el paso de cobro QR en lugar del form.
  _MpQrStep? _mpQrStep;
  _PvsQrStep? _pvsQrStep;

  void _setMpQrStep(_MpQrStep? step) {
    setState(() {
      _mpQrStep = step;
      if (step != null) _pvsQrStep = null;
    });
    context.read<UiBloc>().add(SetMpQrActive(step != null || _pvsQrStep != null));
  }

  void _setPvsQrStep(_PvsQrStep? step) {
    setState(() {
      _pvsQrStep = step;
      if (step != null) _mpQrStep = null;
    });
    context.read<UiBloc>().add(SetMpQrActive(step != null || _mpQrStep != null));
  }

  @override
  Widget build(BuildContext context) {
    final pmState = context.read<PaymentMethodsBloc>().state;
    final defaultPaymentMethod =
        pmState is PaymentMethodsLoaded ? pmState.selectedPaymentMethod : null;

    final uiState = context.read<UiBloc>().state;
    final isReturnMode = uiState is UiLoaded ? uiState.isReturnMode : false;

    return BlocProvider(
      create: (context) => CheckoutConfirmationCubit(
        fetchReturnReasonsUsecase: di.sl(),
        calculateOrderTaxesUseCase: di.sl(),
        cartBloc: context.read<CartBloc>(),
        clientsBloc: context.read<ClientsBloc>(),
      )..load(defaultPaymentMethod, isReturnMode: isReturnMode),
      child: BlocBuilder<CartBloc, CartState>(
        builder: (context, cartState) {
          if (cartState is! CartLoaded) {
            return const SizedBox.shrink();
          }

          final uiState = context.watch<UiBloc>().state;
          final isReturnMode =
              uiState is UiLoaded ? uiState.isReturnMode : false;
          final showingMpQr = _mpQrStep != null;
          final showingPvsQr = _pvsQrStep != null;
          final showingQr = showingMpQr || showingPvsQr;

          return BlocBuilder<CheckoutConfirmationCubit,
              CheckoutConfirmationState>(
            builder: (context, confirmationState) {
              final totalAmount = confirmationState.totalAmount;

              return BlocBuilder<CheckoutBloc, CheckoutState>(
                builder: (context, checkoutState) {
                  final isProcessing = checkoutState is CheckoutProcessing;

                  return Column(
                    children: [
                      _buildHeader(
                        context,
                        isReturnMode: isReturnMode,
                        showingMpQr: showingQr,
                        isProcessing: isProcessing,
                        confirmationState: confirmationState,
                      ),
                      Expanded(
                        child: showingMpQr
                            ? Padding(
                                padding: const EdgeInsets.all(
                                    AppDimensions.paddingM),
                                child: MercadoPagoQrPanelView(
                                  amount: _mpQrStep!.amount,
                                  onApproved: (result) =>
                                      _onMpQrApproved(context, result),
                                  onCancelled: _exitMpQrStep,
                                ),
                              )
                            : showingPvsQr
                                ? Padding(
                                    padding: const EdgeInsets.all(
                                        AppDimensions.paddingM),
                                    child: PvsQrPanelView(
                                      amount: _pvsQrStep!.amount,
                                      paymentMethodId:
                                          _pvsQrStep!.paymentMethodId,
                                      onApproved: (result) =>
                                          _onPvsQrApproved(context, result),
                                      onCancelled: _exitPvsQrStep,
                                    ),
                                  )
                                : SingleChildScrollView(
                                padding: const EdgeInsets.all(
                                    AppDimensions.paddingL),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (isReturnMode)
                                      ReturnConfirmationView(
                                        totalAmount: totalAmount,
                                        isLoadingReasons:
                                            confirmationState.isLoading,
                                        returnReasons:
                                            confirmationState.returnReasons,
                                        selectedReturnReasonId:
                                            confirmationState
                                                .selectedReturnReasonId,
                                        onReturnReasonChanged: (id) {
                                          if (id != null) {
                                            context
                                                .read<
                                                    CheckoutConfirmationCubit>()
                                                .selectReturnReason(id);
                                          }
                                        },
                                      )
                                    else
                                      CheckoutConfirmationView(
                                        totalAmount: totalAmount,
                                        iibbAmount:
                                            confirmationState.iibbAmount,
                                        vatPerceptionAmount: confirmationState
                                            .vatPerceptionAmount,
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
                                          color: AppColors.info
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
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
                      if (!showingQr)
                        _buildFooter(
                          context,
                          isReturnMode: isReturnMode,
                          isProcessing: isProcessing,
                          confirmationState: confirmationState,
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

  Widget _buildHeader(
    BuildContext context, {
    required bool isReturnMode,
    required bool showingMpQr,
    required bool isProcessing,
    required CheckoutConfirmationState confirmationState,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingM,
        vertical: AppDimensions.paddingXS,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: isProcessing
                ? null
                : () {
                    if (showingMpQr) {
                      _exitMpQrStep();
                      _exitPvsQrStep();
                    } else {
                      _handleClose();
                    }
                  },
          ),
          const SizedBox(width: AppDimensions.paddingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isReturnMode ? 'Confirmar Devolución' : 'Confirmar Pago',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (!showingMpQr &&
                    confirmationState.activeBranchName != null) ...[
                  const SizedBox(height: 2),
                  if (confirmationState.allowedBranches.length > 1)
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
                            value: confirmationState.activeBranchId,
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
                            items:
                                confirmationState.allowedBranches.map((branch) {
                              return DropdownMenuItem<int>(
                                value: branch.id,
                                child: Text(branch.name),
                              );
                            }).toList(),
                            onChanged: (branchId) {
                              if (branchId != null) {
                                context
                                    .read<CheckoutConfirmationCubit>()
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
    );
  }

  Widget _buildFooter(
    BuildContext context, {
    required bool isReturnMode,
    required bool isProcessing,
    required CheckoutConfirmationState confirmationState,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingL,
        vertical: AppDimensions.paddingS,
      ),
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
                onPressed:
                    isProcessing || !confirmationState.isValid(isReturnMode)
                        ? null
                        : () {
                            if (isReturnMode) {
                              _confirmReturn(context);
                            } else {
                              _confirmSale(context);
                            }
                          },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isReturnMode ? AppColors.warning : AppColors.success,
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
                              AlwaysStoppedAnimation<Color>(Colors.white),
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
    );
  }

  Future<void> _confirmSale(BuildContext context) async {
    final confirmationCubit = context.read<CheckoutConfirmationCubit>();
    final payments = confirmationCubit.state.selectedPayments;

    PaymentMethod? mpPayment;
    PaymentMethod? pvsPayment;
    for (final pm in payments) {
      if (mpPayment == null && isMercadoPagoQrMethod(pm)) {
        mpPayment = pm;
      }
      if (pvsPayment == null && isPvsQrMethod(pm)) {
        pvsPayment = pm;
      }
    }

    if (mpPayment != null) {
      final hasCredentials =
          await di.sl<MercadoPagoRepository>().hasValidCredentials();
      if (!hasCredentials) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Mercado Pago no está configurado para este cajero (token/caja).',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final amount = mpPayment.amount ?? 0.0;
      if (amount <= 0) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El monto del pago QR debe ser mayor a 0'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final mpIndex = payments.indexWhere((pm) => pm.id == mpPayment!.id);
      if (!context.mounted) return;
      _setMpQrStep(_MpQrStep(amount: amount, paymentIndex: mpIndex));
      return;
    }

    if (pvsPayment != null) {
      final amount = pvsPayment.amount ?? 0.0;
      if (amount <= 0) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El monto del pago QR debe ser mayor a 0'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final enterprise =
          await di.sl<AuthLocalDataSource>().getCachedEnterprise();
      final enterpriseId = enterprise?.id;
      if (enterpriseId == null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Empresa no configurada para cobro PVS'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final credentials = await di.sl<PvsRepository>().resolveCredentials(
            enterpriseId: enterpriseId,
            paymentMethodId: pvsPayment.id,
          );
      if (credentials == null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No hay credenciales PVS para este método de pago.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final pvsIndex = payments.indexWhere((pm) => pm.id == pvsPayment!.id);
      if (!context.mounted) return;
      _setPvsQrStep(_PvsQrStep(
        amount: amount,
        paymentIndex: pvsIndex,
        paymentMethodId: pvsPayment.id,
      ));
      return;
    }

    _processSale(context);
  }

  void _onMpQrApproved(BuildContext context, MpPaymentResult result) {
    final confirmationCubit = context.read<CheckoutConfirmationCubit>();
    final step = _mpQrStep;
    if (step != null && step.paymentIndex >= 0) {
      confirmationCubit.updatePaymentDetails(
        step.paymentIndex,
        PaymentMethodDetails(
          transferId: result.paymentId,
          verificationId: result.referenceId,
          orderId: result.orderId,
        ),
      );
    }
    _setMpQrStep(null);
    _processSale(context);
  }

  void _onPvsQrApproved(BuildContext context, PvsPaymentResult result) {
    final confirmationCubit = context.read<CheckoutConfirmationCubit>();
    final step = _pvsQrStep;
    if (step != null && step.paymentIndex >= 0) {
      confirmationCubit.updatePaymentDetails(
        step.paymentIndex,
        PaymentMethodDetails(
          transferId: result.paymentId,
          orderId: result.orderId,
        ),
      );
    }
    _setPvsQrStep(null);
    _processSale(context);
  }

  void _exitMpQrStep() {
    _setMpQrStep(null);
  }

  void _exitPvsQrStep() {
    _setPvsQrStep(null);
  }

  void _processSale(BuildContext context) {
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

  void _handleClose() {
    widget.onClose();
  }
}

class _MpQrStep {
  final double amount;
  final int paymentIndex;

  const _MpQrStep({
    required this.amount,
    required this.paymentIndex,
  });
}

class _PvsQrStep {
  final double amount;
  final int paymentIndex;
  final int paymentMethodId;

  const _PvsQrStep({
    required this.amount,
    required this.paymentIndex,
    required this.paymentMethodId,
  });
}
