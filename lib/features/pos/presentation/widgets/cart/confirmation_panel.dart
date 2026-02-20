import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/features/pos/data/datasources/printer_local_datasource.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_state.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/checkout/checkout_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/checkout/checkout_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/checkout/checkout_state.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/clients/clients_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/clients/clients_state.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/payment_methods/payment_methods_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/payment_methods/payment_methods_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/payment_methods/payment_methods_state.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/printer/printer_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/printer/printer_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/printer/printer_state.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/cash_payment_widget.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/payment_option_widget.dart';
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

  @override
  Widget build(BuildContext context) {
    return BlocListener<CheckoutBloc, CheckoutState>(
      listener: (context, checkoutState) async {
        if (checkoutState is CheckoutSuccess) {
          // Imprimir el ticket si el estado es success
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

          

          if (mounted) {
            context.read<CartBloc>().add(ClearCart());
            context.read<CheckoutBloc>().add(const ResetCheckout());
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(checkoutState.message),
                backgroundColor: AppColors.error,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      },
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
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
                    // Métodos de pago
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
                            padding:
                                const EdgeInsets.all(AppDimensions.paddingM),
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
                                    color: AppColors.warning.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.warning.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.warning,
                                          size: 20, color: AppColors.warning),
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
                                                  .selectedPaymentMethod?.id ==
                                              cashPayment.id,
                                          isEnabled: true,
                                          onTap: () {
                                            context
                                                .read<PaymentMethodsBloc>()
                                                .add(SelectPaymentMethodEvent(
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

                    CashPaymentWidget(
                      key: ValueKey(state.subtotal + state.totalIva),
                      totalAmount: state.subtotal + state.totalIva,
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
                        padding: const EdgeInsets.all(AppDimensions.paddingM),
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
                              child: CircularProgressIndicator(strokeWidth: 2),
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
            total: cartState.total,
            totalIva: cartState.totalIva,
            client: selectedClient,
            paymentMethod: selectedPaymentMethod,
            receivedAmount: _receivedAmount,
            change: _change,
          ),
        );
  }
}
