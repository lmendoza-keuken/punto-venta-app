import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/features/pos/domain/entities/payment_method.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/payment_methods/payment_methods_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/payment_methods/payment_methods_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/payment_methods/payment_methods_state.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/cash_payment_widget.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/payment_method_dialogs.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/confirmation/checkout_confirmation/payment_method_details_controllers.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/confirmation/checkout_confirmation/payment_row_widget.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/confirmation/checkout_confirmation/payment_additional_details_widget.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/confirmation/confirmation_helpers.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/confirmation/checkout_confirmation/multiple_payments_section.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/confirmation/checkout_confirmation/single_payment_section.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/confirmation/checkout_confirmation/payment_tax_breakdown.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/checkout_confirmation/checkout_confirmation_cubit.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/checkout_confirmation/checkout_confirmation_state.dart';

class CheckoutConfirmationView extends StatefulWidget {
  final double totalAmount;

  // Impuestos extra (IIBB, perc. IVA, imp. interno)
  final double iibbAmount;
  final double vatPerceptionAmount;
  final double internalTaxAmount;

  // Para el desglose de impuestos
  final double cartSubtotal;
  final double cartTotalIva;

  const CheckoutConfirmationView({
    super.key,
    required this.totalAmount,
    required this.iibbAmount,
    required this.vatPerceptionAmount,
    required this.internalTaxAmount,
    required this.cartSubtotal,
    required this.cartTotalIva,
  });

  @override
  State<CheckoutConfirmationView> createState() =>
      _CheckoutConfirmationViewState();
}

class _CheckoutConfirmationViewState extends State<CheckoutConfirmationView> {
  final List<TextEditingController> _amountControllers = [];
  final List<TextEditingController> _receivedControllers = [];
  final List<PaymentMethodDetailsControllers> _detailsControllers = [];
  final Set<int> _expandedPaymentDetails = {};

  @override
  void initState() {
    super.initState();
    final cubit = context.read<CheckoutConfirmationCubit>();
    _syncControllersAndText(cubit.state.selectedPayments);
  }

  @override
  void didUpdateWidget(covariant CheckoutConfirmationView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.totalAmount != oldWidget.totalAmount) {
      final cubit = context.read<CheckoutConfirmationCubit>();
      _syncControllersAndText(cubit.state.selectedPayments);
    }
  }

  @override
  void dispose() {
    for (final controller in _amountControllers) {
      controller.dispose();
    }
    for (final controller in _receivedControllers) {
      controller.dispose();
    }
    for (final controller in _detailsControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _syncControllersAndText(List<PaymentMethod> payments) {
    // 1. Sync length of amountControllers
    while (_amountControllers.length < payments.length) {
      _amountControllers.add(TextEditingController());
    }
    while (_amountControllers.length > payments.length) {
      _amountControllers.last.dispose();
      _amountControllers.removeLast();
    }

    // 2. Sync length of receivedControllers
    while (_receivedControllers.length < payments.length) {
      _receivedControllers.add(TextEditingController());
    }
    while (_receivedControllers.length > payments.length) {
      _receivedControllers.last.dispose();
      _receivedControllers.removeLast();
    }

    // 3. Sync length of detailsControllers
    while (_detailsControllers.length < payments.length) {
      _detailsControllers.add(PaymentMethodDetailsControllers());
    }
    while (_detailsControllers.length > payments.length) {
      _detailsControllers.last.dispose();
      _detailsControllers.removeLast();
    }

    // 4. Update text values if they differ from model to avoid losing focus/cursor position
    for (int i = 0; i < payments.length; i++) {
      final pm = payments[i];

      // Sync amount
      final amountStr = pm.amount?.toStringAsFixed(2) ?? '';
      final currentAmountParsed = double.tryParse(_amountControllers[i].text);
      if (_amountControllers[i].text != amountStr &&
          currentAmountParsed != pm.amount) {
        _amountControllers[i].text = amountStr;
      }

      // Sync received amount (for cash)
      final isCash = pm.description.toLowerCase().contains('efectivo') ||
          pm.shortDescription.toLowerCase().contains('efectivo');
      if (isCash) {
        final rec = pm.receivedAmount ?? pm.amount ?? 0.0;
        final recStr = rec.toStringAsFixed(2);
        final currentRecParsed = double.tryParse(_receivedControllers[i].text);
        if (_receivedControllers[i].text != recStr && currentRecParsed != rec) {
          _receivedControllers[i].text = recStr;
        }
      }

      // Sync details controllers
      final details = pm.details ?? const PaymentMethodDetails();
      if (_detailsControllers[i].accountOwner.text !=
          (details.accountOwner ?? '')) {
        _detailsControllers[i].accountOwner.text = details.accountOwner ?? '';
      }
      if (_detailsControllers[i].bankId.text != (details.bankId ?? '')) {
        _detailsControllers[i].bankId.text = details.bankId ?? '';
      }
      if (_detailsControllers[i].checkNumber.text !=
          (details.checkNumber ?? '')) {
        _detailsControllers[i].checkNumber.text = details.checkNumber ?? '';
      }
      if (_detailsControllers[i].transferId.text !=
          (details.transferId ?? '')) {
        _detailsControllers[i].transferId.text = details.transferId ?? '';
      }
      if (_detailsControllers[i].verificationId.text !=
          (details.verificationId ?? '')) {
        _detailsControllers[i].verificationId.text =
            details.verificationId ?? '';
      }
    }
  }

  void _updatePaymentDetails(int index,
      PaymentMethodDetails Function(PaymentMethodDetails d) updateFn) {
    final payments =
        context.read<CheckoutConfirmationCubit>().state.selectedPayments;
    if (index >= payments.length) return;
    final currentDetails =
        payments[index].details ?? const PaymentMethodDetails();
    final updatedDetails = updateFn(currentDetails);
    context
        .read<CheckoutConfirmationCubit>()
        .updatePaymentDetails(index, updatedDetails);
  }

  Widget _buildDetailsFormWidget(int index, PaymentMethod pm,
      PaymentMethodDetailsControllers controllers) {
    final isExpanded = _expandedPaymentDetails.contains(pm.id);

    return PaymentAdditionalDetailsWidget(
      paymentMethod: pm,
      controllers: controllers,
      isExpanded: isExpanded,
      onExpansionToggled: () {
        setState(() {
          if (isExpanded) {
            _expandedPaymentDetails.remove(pm.id);
          } else {
            _expandedPaymentDetails.add(pm.id);
          }
        });
      },
      onCheckNumberChanged: (val) {
        _updatePaymentDetails(index, (d) => d.copyWith(checkNumber: val));
      },
      onTransferIdChanged: (val) {
        _updatePaymentDetails(index, (d) => d.copyWith(transferId: val));
      },
      onVerificationIdChanged: (val) {
        _updatePaymentDetails(index, (d) => d.copyWith(verificationId: val));
      },
    );
  }

  Widget _buildPaymentRowWidget(
      int index, PaymentMethod pm, List<PaymentMethod> allAvailableMethods) {
    final isCash = pm.description.toLowerCase().contains('efectivo') ||
        pm.shortDescription.toLowerCase().contains('efectivo');
    final controllers = _detailsControllers[index];

    return PaymentRowWidget(
      paymentMethod: pm,
      amountController: _amountControllers[index],
      receivedController: isCash ? _receivedControllers[index] : null,
      icon: getPaymentMethodIcon(pm.description, pm.shortDescription),
      showDeleteButton: context
              .read<CheckoutConfirmationCubit>()
              .state
              .selectedPayments
              .length >
          1,
      onDelete: () {
        context
            .read<CheckoutConfirmationCubit>()
            .removePaymentMethod(index, widget.totalAmount);
        final nextPayments =
            context.read<CheckoutConfirmationCubit>().state.selectedPayments;
        if (nextPayments.length == 1) {
          context
              .read<PaymentMethodsBloc>()
              .add(SelectPaymentMethodEvent(nextPayments[0]));
        }
      },
      onAmountChanged: (val) {
        final double? parsed = double.tryParse(val);
        context
            .read<CheckoutConfirmationCubit>()
            .updatePaymentAmount(index, parsed ?? 0.0, widget.totalAmount);
      },
      onReceivedAmountChanged: (val) {
        final double? parsed = double.tryParse(val);
        context
            .read<CheckoutConfirmationCubit>()
            .updatePaymentReceivedAmount(index, parsed, widget.totalAmount);
      },
      detailsWidget: _buildDetailsFormWidget(index, pm, controllers),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<PaymentMethodsBloc, PaymentMethodsState>(
          listener: (context, pmState) {
            if (pmState is PaymentMethodsLoaded) {
              final selected = pmState.selectedPaymentMethod;
              if (selected != null) {
                context
                    .read<CheckoutConfirmationCubit>()
                    .selectSinglePaymentMethod(selected, widget.totalAmount);
              }
            }
          },
        ),
        BlocListener<CheckoutConfirmationCubit, CheckoutConfirmationState>(
          listenWhen: (previous, current) =>
              previous.selectedPayments != current.selectedPayments,
          listener: (context, state) {
            _syncControllersAndText(state.selectedPayments);
          },
        ),
      ],
      child: BlocBuilder<CheckoutConfirmationCubit, CheckoutConfirmationState>(
        builder: (context, confirmationState) {
          final selectedPayments = confirmationState.selectedPayments;
          final totalAllocated = confirmationState.totalAllocated;
          final change = confirmationState.change;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Métodos de Pago',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              BlocBuilder<PaymentMethodsBloc, PaymentMethodsState>(
                builder: (context, pmState) {
                  if (pmState is PaymentMethodsLoading) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (pmState is PaymentMethodsError) {
                    return Container(
                      padding: const EdgeInsets.all(AppDimensions.paddingM),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              size: 20, color: AppColors.error),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Error al cargar métodos de pago: ${pmState.message}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (pmState is PaymentMethodsLoaded) {
                    final paymentMethods = pmState.paymentMethods;
                    final selected = pmState.selectedPaymentMethod;

                    if (paymentMethods.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(AppDimensions.paddingM),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning,
                                size: 20, color: AppColors.warning),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'No hay métodos de pago disponibles',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (selectedPayments.length > 1) {
                      return MultiplePaymentsSection(
                        paymentRows: List.generate(
                          selectedPayments.length,
                          (index) => _buildPaymentRowWidget(
                              index, selectedPayments[index], paymentMethods),
                        ),
                        onAddMethodPressed: () => showAddPaymentMethodDialog(
                          context: context,
                          allMethods: paymentMethods,
                          selectedPayments: selectedPayments,
                          totalAmount: widget.totalAmount,
                          totalAllocated: totalAllocated,
                          getPaymentMethodIcon: getPaymentMethodIcon,
                          onMethodAdded: (pm, defaultAmount) {
                            context
                                .read<CheckoutConfirmationCubit>()
                                .addPaymentMethod(
                                    pm, defaultAmount, widget.totalAmount);
                          },
                        ),
                        totalAmount: widget.totalAmount,
                        totalAllocated: totalAllocated,
                        change: change,
                      );
                    }
                    return SinglePaymentSection(
                      selectedPayment: selected,
                      onSelectorTap: () => showPaymentMethodsSelectorDialog(
                        context: context,
                        paymentMethods: paymentMethods,
                        selectedPaymentMethod: selected,
                        getPaymentMethodIcon: getPaymentMethodIcon,
                        onSelected: (pm) {
                          context
                              .read<PaymentMethodsBloc>()
                              .add(SelectPaymentMethodEvent(pm));
                        },
                      ),
                      detailsWidget: selectedPayments.isNotEmpty
                          ? _buildDetailsFormWidget(
                              0, selectedPayments[0], _detailsControllers[0])
                          : null,
                      onAddMethodPressed: () => showAddPaymentMethodDialog(
                        context: context,
                        allMethods: paymentMethods,
                        selectedPayments: selectedPayments,
                        totalAmount: widget.totalAmount,
                        totalAllocated: totalAllocated,
                        getPaymentMethodIcon: getPaymentMethodIcon,
                        onMethodAdded: (pm, defaultAmount) {
                          context
                              .read<CheckoutConfirmationCubit>()
                              .addPaymentMethod(
                                  pm, defaultAmount, widget.totalAmount);
                        },
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 24),
              const Divider(height: 1),
              const SizedBox(height: 24),
              if (widget.iibbAmount > 0 ||
                  widget.vatPerceptionAmount > 0 ||
                  widget.internalTaxAmount > 0)
                PaymentTaxBreakdown(
                  cartSubtotal: widget.cartSubtotal,
                  cartTotalIva: widget.cartTotalIva,
                  iibbAmount: widget.iibbAmount,
                  vatPerceptionAmount: widget.vatPerceptionAmount,
                  internalTaxAmount: widget.internalTaxAmount,
                ),
              if (selectedPayments.length <= 1)
                CashPaymentWidget(
                  key: ValueKey(widget.totalAmount),
                  totalAmount: widget.totalAmount,
                  onAmountChanged: (amount) {
                    context
                        .read<CheckoutConfirmationCubit>()
                        .updatePaymentReceivedAmount(
                            0, amount, widget.totalAmount);
                  },
                  onChangeCalculated: (changeVal) {},
                ),
            ],
          );
        },
      ),
    );
  }
}
