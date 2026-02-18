import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/core/utils/extensions.dart';
import 'package:punto_venta_app/features/auth/data/datasources/auth_local_datasources.dart';
import 'package:punto_venta_app/features/pos/data/datasources/price_list_local_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/printer_local_datasource.dart';
import 'package:punto_venta_app/features/pos/domain/entities/print_job.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/complete_order_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/get_pdv_config_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/send_invoice_usecase.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_state.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/clients/clients_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/clients/clients_state.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/printer/printer_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/printer/printer_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/printer/printer_state.dart';
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
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.paddingM),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.info_outline,
                              size: 20, color: AppColors.primary),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Por el momento solo está habilitado el pago en efectivo.',
                              style: TextStyle(
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      spacing: AppDimensions.paddingS,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Opciones de pago
                        _buildPaymentOption(
                          icon: Icons.attach_money,
                          iconColor: AppColors.success,
                          title: 'Efectivo',
                          subtitle: 'Opción habilitada',
                          enabled: true,
                        ),
                        _buildPaymentOption(
                          icon: Icons.credit_card,
                          iconColor: Colors.grey,
                          title: 'Tarjeta',
                          subtitle: 'No disponible',
                          enabled: false,
                        ),
                        _buildPaymentOption(
                          icon: Icons.phone_iphone,
                          iconColor: Colors.grey,
                          title: 'MercadoPago / QR',
                          subtitle: 'No disponible',
                          enabled: false,
                        ),
                      ],
                    ),

                    // const SizedBox(height: 24),
                    // const Divider(height: 1),
                    // const SizedBox(height: 24),

                    // Detalle de totales (IVA, subtotal)

                    // Text(
                    //   'Resumen',
                    //   style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    //         fontWeight: FontWeight.bold,
                    //       ),
                    // ),
                    // const SizedBox(height: 16),

                    // _buildTotalRow('Subtotal:', state.subtotal),
                    // const SizedBox(height: 8),
                    // _buildTotalRow('IVA:', state.totalIva),
                    // const SizedBox(height: 12),

                    const Divider(),
                    const SizedBox(height: 12),
                    _buildTotalRow(
                      'Total a cobrar:',
                      state.subtotal + state.totalIva,
                      isTotal: true,
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

  Widget _buildPaymentOption({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool enabled,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingS),
      decoration: BoxDecoration(
        color: enabled
            ? AppColors.success.withOpacity(0.05)
            : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enabled
              ? AppColors.success.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                fontSize: isTotal ? 20 : 16,
              ),
        ),
        Text(
          amount.formatToCurrency(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: isTotal ? 24 : 16,
                color: isTotal ? AppColors.primary : null,
              ),
        ),
      ],
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

      final pdvConfigUsecase = di.sl<GetAppConfigUsecase>();
      final pdvConfig = await pdvConfigUsecase();

      // Obtener cliente seleccionado del ClientsBloc
      final clientsState = context.read<ClientsBloc>().state;
      final selectedClient =
          clientsState is ClientsLoaded ? clientsState.selectedClient : null;

      bool showSubtotalAndTax = false;
      bool showPricesWithTax = true;

      if (pdvConfig != null) {
        if (pdvConfig.showSubtotalAndTax && selectedClient != null) {
          showSubtotalAndTax = true;
        } else {
          showSubtotalAndTax = false;
        }

        showPricesWithTax = pdvConfig.showPricesWithTax;
      }

      final completeOrderUsecase = di.sl<CompleteOrderUsecase>();
      await completeOrderUsecase(
        items: cartState.items,
        logItems: cartState.log,
        total: cartState.total,
        clientName: selectedClient?.name,
        cashierName: user?.name ?? 'Desconocido',
        showSubtotalAndTax: showSubtotalAndTax,
        showPricesWithTax: showPricesWithTax,
      );

      final printJob = PrintJob(
        items: cartState.items,
        logItems: cartState.log,
        total: cartState.total,
        clientName: selectedClient?.name,
        client: selectedClient,
        priceListId: priceList,
        totalTax: totalTax,
        paymentMethod: 'Efectivo',
        cashierName: user?.name ?? 'Desconocido',
        cashierId: int.tryParse(user?.id ?? ''),
        timestamp: DateTime.now(),
        ticketId: DateTime.now().millisecondsSinceEpoch.toString(),
        enterprise: enterprise,
        showSubtotalAndTax: showSubtotalAndTax,
        showPricesWithTax: showPricesWithTax,
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
