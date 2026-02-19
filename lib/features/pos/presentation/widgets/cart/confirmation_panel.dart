import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/features/auth/data/datasources/auth_local_datasources.dart';
import 'package:punto_venta_app/features/pos/data/datasources/pdv_local_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/price_list_local_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/printer_local_datasource.dart';
import 'package:punto_venta_app/features/pos/domain/entities/print_job.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/complete_order_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/get_ticket_config_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/send_invoice_usecase.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_state.dart';
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
  bool _isProcessingSale = false;
  double? _receivedAmount;
  double? _change;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, state) {
        if (state is! CartLoaded) {
          return const SizedBox.shrink();
        }

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
                    onPressed: _isProcessingSale ? null : widget.onClose,
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

                    if (_isProcessingSale) ...[
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
                        onPressed: _isProcessingSale
                            ? null
                            : () => _confirmSale(context, state),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isProcessingSale
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
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
                        onPressed: _isProcessingSale ? null : widget.onClose,
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
  }

  Future<void> _confirmSale(BuildContext context, CartLoaded cartState) async {
    setState(() {
      _isProcessingSale = true;
    });

    try {
      final user = await di.sl<AuthLocalDataSource>().getCachedUser();
      final printerConfig =
          await di.sl<PrinterLocalDataSource>().getPrinterConfig();
      final priceList =
          await di.sl<PriceListLocalDataSource>().getCurrentPriceList();
      final localDs = di.sl<AuthLocalDataSource>();
      final enterprise = await localDs.getCachedEnterprise();

      final totalTax = cartState.totalIva;

      final appConfigUsecase = di.sl<GetTicketConfigUsecase>();
      final appConfig = await appConfigUsecase();

      // Obtener cliente seleccionado del ClientsBloc
      final clientsState = context.read<ClientsBloc>().state;
      final selectedClient =
          clientsState is ClientsLoaded ? clientsState.selectedClient : null;

      // Obtener método de pago seleccionado del PaymentMethodsBloc
      final paymentMethodsState = context.read<PaymentMethodsBloc>().state;
      final selectedPaymentMethod = paymentMethodsState is PaymentMethodsLoaded
          ? paymentMethodsState.selectedPaymentMethod
          : null;
      final config = await di.sl<PdvLocalDataSource>().getPdvConfig();
      // Numero de sucursal para incluir en el ticket
      final branchNumber = config?.branchNumber;

      // Bloquear cobro si no hay número de sucursal configurado
      if (branchNumber == null || branchNumber.trim().isEmpty) {
        if (mounted) {
          setState(() {
            _isProcessingSale = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Configure el número de sucursal antes de realizar cobros.',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      bool showSubtotalAndTax = false;
      bool showPricesWithTax = true;

      if (appConfig != null) {
        if (appConfig.showSubtotalAndTax && selectedClient != null) {
          showSubtotalAndTax = true;
        } else {
          showSubtotalAndTax = false;
        }

        showPricesWithTax = appConfig.showPricesWithTax;
      }

      final completeOrderUsecase = di.sl<CompleteOrderUsecase>();
      await completeOrderUsecase(
        items: cartState.items,
        logItems: cartState.log,
        total: cartState.total,
        clientName: selectedClient?.name,
        paymentMethod: selectedPaymentMethod,
        cashierName: user?.name ?? 'Desconocido',
        showSubtotalAndTax: showSubtotalAndTax,
        showPricesWithTax: showPricesWithTax,
        receivedAmount: _receivedAmount,
        change: _change,
      );

      final printJob = PrintJob(
        items: cartState.items,
        logItems: cartState.log,
        total: cartState.total,
        clientName: selectedClient?.name,
        client: selectedClient,
        priceListId: priceList,
        totalTax: totalTax,
        paymentMethod: selectedPaymentMethod,
        cashierName: user?.name ?? 'Desconocido',
        cashierId: int.tryParse(user?.id ?? ''),
        timestamp: DateTime.now(),
        ticketId: DateTime.now().millisecondsSinceEpoch.toString(),
        enterprise: enterprise,
        showSubtotalAndTax: showSubtotalAndTax,
        showPricesWithTax: showPricesWithTax,
        receivedAmount: _receivedAmount,
        change: _change,
        branchNumber: branchNumber ?? '',
      );

      final sendInvoice = di.sl<SendInvoiceUseCase>();
      bool invoiceSent = false;

      try {
        invoiceSent = await sendInvoice(printJob);
      } catch (e) {
        if (mounted) {
          setState(() {
            _isProcessingSale = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: No se pudo enviar la factura - $e'),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      if (!invoiceSent) {
        if (mounted) {
          setState(() {
            _isProcessingSale = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: La factura no se pudo enviar'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      if (mounted) {
        // Crear e inicializar el PrinterBloc
        final printerBloc = di.sl<PrinterBloc>();
        printerBloc.add(PrintTicket(
          printJob: printJob,
          config: printerConfig,
        ));

        await printerBloc.stream.firstWhere(
          (state) => state is PrinterSuccess || state is PrinterError,
        );

        context.read<CartBloc>().add(ClearCart());

        widget.onClose();

        setState(() {
          _isProcessingSale = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Venta procesada exitosamente'),
            backgroundColor: AppColors.success,
          ),
        );

        printerBloc.close();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessingSale = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar venta: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
