import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/features/pos/data/datasources/printer_local_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/pdv_local_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/branch_local_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/vat_category_local_datasource.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_state.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/checkout/checkout_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/checkout/checkout_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/checkout/checkout_state.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/clients/clients_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/clients/clients_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/clients/clients_state.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/payment_methods/payment_methods_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/payment_methods/payment_methods_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/payment_methods/payment_methods_state.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/printer/printer_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/printer/printer_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/printer/printer_state.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/cash_payment_widget.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/payment_option_widget.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/common/error_dialog.dart';
import 'package:punto_venta_app/features/pos/presentation/utils/iibb_calculator.dart';
import 'package:punto_venta_app/features/pos/presentation/utils/vat_perception_calculator.dart';
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
  double? _receivedAmount;
  double? _change;
  double _iibbAmount = 0.0;
  double _vatPerceptionAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _calculateTaxesForUI();
  }

  Future<void> _calculateTaxesForUI() async {
    try {
      final clientsState = context.read<ClientsBloc>().state;
      final selectedClient =
          clientsState is ClientsLoaded ? clientsState.selectedClient : null;

      if (selectedClient == null) {
        setState(() {
          _iibbAmount = 0.0;
          _vatPerceptionAmount = 0.0;
        });
        return;
      }

      final cartState = context.read<CartBloc>().state;
      if (cartState is! CartLoaded) {
        setState(() {
          _iibbAmount = 0.0;
          _vatPerceptionAmount = 0.0;
        });
        return;
      }

      // Obtener configuración del PDV (branch)
      final pdvConfig = await di.sl<PdvLocalDataSource>().getPdvConfig();
      final branchId = pdvConfig?.branchId;
      
      if (branchId == null) {
        setState(() {
          _iibbAmount = 0.0;
          _vatPerceptionAmount = 0.0;
        });
        return;
      }

      // Obtener branch
      final branch = await di.sl<BranchLocalDataSource>().getBranchById(branchId);

      // Obtener VAT category
      final vatCategoryId = selectedClient.vatCategoryId;
      final vatCategoryDataSource = di.sl<VatCategoryLocalDataSource>();
      final allVatCategories = await vatCategoryDataSource.getCachedVatCategories();
      final vatCategory = allVatCategories
          ?.where((cat) => cat.id == vatCategoryId)
          .firstOrNull;

      // Calcular IIBB
      final iibb = IibbCalculator.calculateIibb(
        client: selectedClient,
        branch: branch,
        vatCategory: vatCategory,
        subtotal: cartState.subtotal,
        totalWithVat: cartState.subtotal + cartState.totalIva,
      );

      // Calcular percepción de IVA
      final vatPerception = VatPerceptionCalculator.calculateVatPerception(
        cartItems: cartState.items,
        branch: branch,
        vatCategory: vatCategory,
      );

      setState(() {
        _iibbAmount = iibb;
        _vatPerceptionAmount = vatPerception;
      });
    } catch (e) {
      setState(() {
        _iibbAmount = 0.0;
        _vatPerceptionAmount = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ClientsBloc, ClientsState>(
          listener: (context, clientsState) {
            // Recalcular impuestos cuando cambia el cliente
            _calculateTaxesForUI();
          },
        ),
        BlocListener<CartBloc, CartState>(
          listener: (context, cartState) {
            // Recalcular impuestos cuando cambia el carrito
            _calculateTaxesForUI();
          },
        ),
        BlocListener<CheckoutBloc, CheckoutState>(
          listener: (context, checkoutState) async {
            if (checkoutState is CheckoutSuccess) {
              final printerConfig =
                  await di.sl<PrinterLocalDataSource>().getPrinterConfig();
              final printerBloc = di.sl<PrinterBloc>();

              printerBloc.add(PrintTicket(
                printJob: checkoutState.printJob,
                config: printerConfig,
              ));

              await printerBloc.stream.firstWhere(
                (state) => state is PrinterSuccess || state is PrinterError,
              );

              // Limpiar el carrito y cerrar el panel de confirmación
              if (mounted) {
                context.read<CartBloc>().add(ClearCart());
                context.read<CheckoutBloc>().add(const ResetCheckout());
                context.read<ClientsBloc>().add(ResetToDefaultClientEvent());
                widget.onClose();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Venta procesada exitosamente'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }

              printerBloc.close();
            } else if (checkoutState is CheckoutError) {
              if (mounted) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext dialogContext) {
                    return ErrorDialog(
                      message: checkoutState.message,
                      onAccept: () {
                        context.read<CheckoutBloc>().add(const ResetCheckout());
                      },
                    );
                  },
                );
              }
            }
          },
        ),
      ],
      child: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          if (state is! CartLoaded) {
            return const SizedBox.shrink();
          }

          return BlocBuilder<CheckoutBloc, CheckoutState>(
            builder: (context, checkoutState) {
              final isProcessing = checkoutState is CheckoutProcessing;

              return Column(
                children: [
                  // Header del panel de confirmación
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
                          icon: const Icon(Icons.arrow_forward),
                          onPressed: isProcessing ? null : widget.onClose,
                        ),
                        const SizedBox(width: AppDimensions.paddingS),
                        Expanded(
                          child: Text(
                            'Confirmar Pago',
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

                  // Contenido del panel de confirmación
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppDimensions.paddingL),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Métodos de Pago',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
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
                                  padding: const EdgeInsets.all(
                                      AppDimensions.paddingM),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.error.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.error_outline,
                                          size: 20, color: AppColors.error),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Error al cargar métodos de pago: ${pmState.message}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              if (pmState is PaymentMethodsLoaded) {
                                final paymentMethods = pmState.paymentMethods;

                                // Filtrar solo el método de efectivo (por ahora)
                                final cashPayment = paymentMethods
                                    .where((pm) =>
                                        pm.description
                                            .toLowerCase()
                                            .contains('efectivo') ||
                                        pm.shortDescription
                                            .toLowerCase()
                                            .contains('efectivo'))
                                    .firstOrNull;

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (paymentMethods.isEmpty)
                                      Container(
                                        padding: const EdgeInsets.all(
                                            AppDimensions.paddingM),
                                        decoration: BoxDecoration(
                                          color: AppColors.warning
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: AppColors.warning
                                                .withOpacity(0.3),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.warning,
                                                size: 20,
                                                color: AppColors.warning),
                                            const SizedBox(width: 12),
                                            const Expanded(
                                              child: Text(
                                                'No hay métodos de pago disponibles',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else
                                      Wrap(
                                        spacing: AppDimensions.paddingM,
                                        runSpacing: AppDimensions.paddingM,
                                        children: [
                                          if (cashPayment != null)
                                            SizedBox(
                                              width: 120,
                                              child: PaymentOptionWidget(
                                                paymentMethod: cashPayment,
                                                isSelected: pmState
                                                        .selectedPaymentMethod
                                                        ?.id ==
                                                    cashPayment.id,
                                                isEnabled: true,
                                                onTap: () {
                                                  context
                                                      .read<
                                                          PaymentMethodsBloc>()
                                                      .add(
                                                          SelectPaymentMethodEvent(
                                                              cashPayment));
                                                },
                                                icon: Icons.attach_money,
                                              ),
                                            ),
                                        ],
                                      ),
                                  ],
                                );
                              }

                              return const SizedBox.shrink();
                            },
                          ),

                          const SizedBox(height: 24),
                          const Divider(height: 1),
                          const SizedBox(height: 24),

                          // Mostrar desglose si aplican percepciones
                          if (_iibbAmount > 0 || _vatPerceptionAmount > 0) ...[
                            Container(
                              padding: const EdgeInsets.all(AppDimensions.paddingM),
                              decoration: BoxDecoration(
                                color: AppColors.info.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.info.withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Subtotal:',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        '\$ ${state.subtotal.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'IVA:',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        '\$ ${state.totalIva.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_iibbAmount > 0) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Percep. IIBB:',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.info,
                                          ),
                                        ),
                                        Text(
                                          '\$ ${_iibbAmount.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.info,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (_vatPerceptionAmount > 0) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Percep. IVA:',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.info,
                                          ),
                                        ),
                                        Text(
                                          '\$ ${_vatPerceptionAmount.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.info,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          CashPaymentWidget(
                            key: ValueKey(state.subtotal + state.totalIva + _iibbAmount + _vatPerceptionAmount),
                            totalAmount: state.subtotal + state.totalIva + _iibbAmount + _vatPerceptionAmount,
                            onAmountChanged: (amount) {
                              setState(() {
                                _receivedAmount = amount;
                              });
                            },
                            onChangeCalculated: (change) {
                              setState(() {
                                _change = change;
                              });
                            },
                          ),

                          if (isProcessing) ...[
                            const SizedBox(height: 24),
                            Container(
                              padding:
                                  const EdgeInsets.all(AppDimensions.paddingM),
                              decoration: BoxDecoration(
                                color: AppColors.info.withOpacity(0.1),
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
                      spacing: AppDimensions.paddingM,
                      children: [
                        Expanded(
                          flex: 1,
                          child: SizedBox(
                            height: AppDimensions.buttonHeightS,
                            child: ElevatedButton(
                              onPressed: isProcessing
                                  ? null
                                  : () => _confirmSale(context, state),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
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
                        Expanded(
                          flex: 1,
                          child: SizedBox(
                            height: AppDimensions.buttonHeightS,
                            child: ElevatedButton(
                              onPressed: isProcessing ? null : widget.onClose,
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
      ),
    );
  }

  // Función para confirmar la venta
  void _confirmSale(BuildContext context, CartLoaded cartState) {
    // Obtener cliente seleccionado
    final clientsState = context.read<ClientsBloc>().state;
    final selectedClient =
        clientsState is ClientsLoaded ? clientsState.selectedClient : null;

    // Obtener método de pago seleccionado
    final paymentMethodsState = context.read<PaymentMethodsBloc>().state;
    final selectedPaymentMethod = paymentMethodsState is PaymentMethodsLoaded
        ? paymentMethodsState.selectedPaymentMethod
        : null;

    // Disparar evento de procesamiento
    context.read<CheckoutBloc>().add(
          ProcessSale(
            items: cartState.items,
            logItems: cartState.log,
            // total y totalIva
            total: cartState.total,
            totalIva: cartState.totalIva,
            subtotal: cartState.subtotal,
            client: selectedClient,
            paymentMethod: selectedPaymentMethod,
            receivedAmount: _receivedAmount,
            change: _change,
          ),
        );
  }
}
