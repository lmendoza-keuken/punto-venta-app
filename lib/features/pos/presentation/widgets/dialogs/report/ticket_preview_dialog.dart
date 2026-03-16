import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/core/constants/ticket_types.dart';
import 'package:punto_venta_app/core/utils/extensions.dart';
import 'package:punto_venta_app/features/auth/data/datasources/auth_local_datasources.dart';
import 'package:punto_venta_app/features/pos/data/datasources/pdv_local_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/printer_local_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/completed_orders_remote_datasource.dart';
import 'package:punto_venta_app/features/pos/data/models/tax_model.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/payment_method_repository.dart';
import 'package:punto_venta_app/features/pos/domain/entities/completed_order.dart';
import 'package:punto_venta_app/features/pos/domain/entities/print_job.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/printer/printer_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/printer/printer_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/printer/printer_state.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/reports/reports_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/reports/reports_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/reports/reports_state.dart';
import 'package:punto_venta_app/injection_container.dart' as di;

class TicketPreviewDialog extends StatelessWidget {
  final CompletedOrder ticket;

  const TicketPreviewDialog({
    super.key,
    required this.ticket,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<PrinterBloc>(),
      child: _TicketPreviewContent(ticket: ticket),
    );
  }
}

class _TicketPreviewContent extends StatefulWidget {
  final CompletedOrder ticket;

  const _TicketPreviewContent({required this.ticket});

  @override
  State<_TicketPreviewContent> createState() => _TicketPreviewContentState();
}

class _TicketPreviewContentState extends State<_TicketPreviewContent> {
  PrintJob? _printJob;
  String _paymentMethodName = 'Desconocido';

  @override
  void initState() {
    super.initState();
    _initializePrintJob();
    _loadPaymentMethod();
  }

  Future<void> _loadPaymentMethod() async {
    try {
      final paymentMethodRepo = di.sl<PaymentMethodRepository>();
      final paymentMethods = await paymentMethodRepo.fetchPaymentMethods();

      final paymentMethod = paymentMethods.firstWhere(
        (pm) => pm.id == widget.ticket.paymentMethod,
        orElse: () => paymentMethods.first,
      );

      if (mounted) {
        setState(() {
          _paymentMethodName = paymentMethod.shortDescription;
        });
      }
    } catch (e) {}
  }

  // Construir el PrintJob a partir de la orden completada
  Future<void> _initializePrintJob() async {
    final localDs = di.sl<AuthLocalDataSource>();
    final enterprise = await localDs.getCachedEnterprise();
    final config = await di.sl<PdvLocalDataSource>().getPdvConfig();
    final branchNumber = config?.branchNumber;

    double iibbAmount = 0.0;
    double iibbPercentage = 0.0;
    double vatPerceptionAmount = 0.0;
    double internalTaxAmount = 0.0;
    double? internalTaxRate;
    double ivaAmount = 0.0;

    try {
      final remoteDataSource = di.sl<CompletedOrdersRemoteDataSource>();
      final invoicePayload =
          await remoteDataSource.getTicketById(widget.ticket.id);

      if (invoicePayload != null && invoicePayload.totalTax.isNotEmpty) {
        // Extraer IVA (id: 1, 2, 3)
        ivaAmount = invoicePayload.totalTax
            .where((tax) => tax.id >= 0 && tax.id <= 3)
            .fold(0.0, (sum, tax) => sum + (tax.amount ?? 0.0));

        // Extraer IIBB (id: 4)
        final iibbTax = invoicePayload.totalTax.firstWhere(
          (tax) => tax.id == 4,
          orElse: () => const TaxModel(id: 4, amount: 0.0),
        );
        iibbAmount = iibbTax.amount ?? 0.0;
        iibbPercentage = iibbTax.percentage ?? 0.0;

        // Extraer VAT Perception (id: 6)
        final vatPercepTax = invoicePayload.totalTax.firstWhere(
          (tax) => tax.id == 6,
          orElse: () => const TaxModel(id: 6, amount: 0.0),
        );
        vatPerceptionAmount = vatPercepTax.amount ?? 0.0;

        // Extraer Impuesto Interno (id: 7)
        final internalTax = invoicePayload.totalTax.firstWhere(
          (tax) => tax.id == 7,
          orElse: () => const TaxModel(id: 7, amount: 0.0),
        );
        internalTaxAmount = internalTax.amount ?? 0.0;
        internalTaxRate = internalTax.percentage;
      }
    } catch (e) {
      ivaAmount = widget.ticket.totalTax;
    }

    final printJob = PrintJob(
      items: widget.ticket.items,
      logItems: widget.ticket.logs,
      total: widget.ticket.total,
      clientName: widget.ticket.clientName,
      totalTax: ivaAmount,
      iibbTax: iibbAmount,
      iibbTaxPercentage: iibbPercentage,
      vatPerception: vatPerceptionAmount,
      internalTax: internalTaxAmount,
      internalTaxRate: internalTaxRate,
      paymentMethod: widget.ticket.paymentMethod,
      cashierName: widget.ticket.cashierName,
      timestamp: widget.ticket.completedAt,
      ticketId: widget.ticket.id,
      enterprise: enterprise,
      showSubtotalAndTax: widget.ticket.showSubtotalAndTax,
      showPricesWithTax: widget.ticket.showPricesWithTax,
      change: widget.ticket.change,
      receivedAmount: widget.ticket.receivedAmount,
      branchNumber: branchNumber ?? '',
    );

    if (mounted) {
      setState(() {
        _printJob = printJob;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_printJob == null) {
      return const Dialog(
        child: SizedBox(
          width: 450,
          height: 200,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return MultiBlocListener(
      listeners: [
        BlocListener<PrinterBloc, PrinterState>(
          listener: (context, state) {
            if (state is PrinterSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } else if (state is PrinterError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        ),
        BlocListener<ReportsBloc, ReportsState>(
          listener: (context, state) {
            if (state is CreditNoteGenerated &&
                state.ticketId == widget.ticket.id) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } else if (state is CreditNoteGenerationError &&
                state.ticketId == widget.ticket.id) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        ),
      ],
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusL),
          side: TicketType.isNotaCredito(widget.ticket.typeCode)
              ? const BorderSide(color: Colors.red, width: 2)
              : BorderSide.none,
        ),
        child: Container(
          width: 450,
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                decoration: BoxDecoration(
                  color: TicketType.isNotaCredito(widget.ticket.typeCode)
                      ? Colors.red.shade50
                      : null,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppDimensions.borderRadiusL),
                    topRight: Radius.circular(AppDimensions.borderRadiusL),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      TicketType.isNotaCredito(widget.ticket.typeCode)
                          ? Icons.receipt_long
                          : Icons.receipt,
                      color: TicketType.isNotaCredito(widget.ticket.typeCode)
                          ? Colors.red.shade700
                          : AppColors.primary,
                    ),
                    const SizedBox(width: AppDimensions.paddingS),
                    if (TicketType.isNotaCredito(widget.ticket.typeCode))
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade700,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'NOTA DE CRÉDITO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (TicketType.isNotaCredito(widget.ticket.typeCode))
                      const SizedBox(width: AppDimensions.paddingS),
                    Expanded(
                      child: Text(
                        'Ticket - ${widget.ticket.id}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: TicketType.isNotaCredito(
                                      widget.ticket.typeCode)
                                  ? Colors.grey.shade900
                                  : null,
                            ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Ticket content
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  child: _buildTicketContent(context),
                ),
              ),

              // Actions
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: BlocBuilder<PrinterBloc, PrinterState>(
                  builder: (context, state) {
                    final isLoading = state is PrinterPrinting;
                    final isCreditNote =
                        TicketType.isNotaCredito(widget.ticket.typeCode);

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: isLoading
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: const Text('Cerrar'),
                        ),
                        const Spacer(),
                        if (!isCreditNote)
                          ElevatedButton.icon(
                            onPressed: isLoading
                                ? null
                                : () => _handleConvertToCreditNote(context),
                            icon: isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Icon(
                                    Icons.receipt,
                                    color: Colors.white,
                                  ),
                            label: Text(isLoading
                                ? 'Convirtiendo...'
                                : 'Pasar a nota de crédito'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                            ),
                          ),
                        if (!isCreditNote)
                          const SizedBox(width: AppDimensions.paddingS),
                        ElevatedButton.icon(
                          onPressed:
                              isLoading ? null : () => _handlePrint(context),
                          icon: isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Icon(
                                  Icons.print,
                                  color: Colors.white,
                                ),
                          label:
                              Text(isLoading ? 'Imprimiendo...' : 'Imprimir'),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handlePrint(BuildContext context) async {
    if (_printJob == null) return;

    final printerConfig =
        await di.sl<PrinterLocalDataSource>().getPrinterConfig();

    // Disparar evento de impresión
    context.read<PrinterBloc>().add(PrintTicket(
          printJob: _printJob!,
          config: printerConfig,
        ));
  }

  void _handleConvertToCreditNote(BuildContext context) {
    context.read<ReportsBloc>().add(GenerateCreditNote(widget.ticket.id ?? ""));
  }

  Widget _buildTicketContent(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header del negocio
            Center(
              child: Column(
                children: [
                  Text(
                    _printJob!.enterprise?.name ?? '',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const Text('Sistema de Punto de Venta'),
                  const Text('comprobante no valido como factura'),
                  // const Text('Tel: (555) 123-4567'),
                  const SizedBox(height: 16),
                  Container(
                    height: 1,
                    color: Colors.black,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ],
              ),
            ),

            // Información de la orden
            Text('Orden: ${widget.ticket.id}'),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    'Fecha: ${DateFormat('dd/MM/yyyy').format(widget.ticket.completedAt)}'),
                Text(
                    'Hora: ${DateFormat('HH:mm:ss').format(widget.ticket.completedAt)}'),
              ],
            ),
            Text('Cajero: ${widget.ticket.cashierName}'),
            if (widget.ticket.clientName != null &&
                widget.ticket.clientName!.isNotEmpty)
              Text('Cliente: ${widget.ticket.clientName}'),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(
                color: Colors.black,
              ),
            ),

            // Items
            ...widget.ticket.items.map((item) {
              final basePrice = item.pricePerKg ?? item.product.price ?? 0.0;
              final displayPrice = _printJob!.showPricesWithTax
                  ? _calculatePriceWithTax(basePrice, item.product.vat)
                  : basePrice;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.description,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    if (item.isWeighted == true)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '  ${item.weightKg ?? '-'} kg x ${displayPrice.formatToCurrency()}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
                          Text(
                            ((item.weightKg ?? 0.0) * displayPrice)
                                .formatToCurrency(),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    if (item.isWeighted != true)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '  ${item.quantity} x ${displayPrice.formatToCurrency()}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
                          Text(
                            (item.quantity * displayPrice).formatToCurrency(),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                  ],
                ),
              );
            }).toList(),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(
                color: Colors.black,
              ),
            ),

            // Totales - Subtotal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal:'),
                Text((widget.ticket.total -
                        _printJob!.totalTax -
                        _printJob!.iibbTax -
                        _printJob!.vatPerception -
                        _printJob!.internalTax)
                    .formatToCurrency()),
              ],
            ),

            // IVA
            if (_printJob!.totalTax > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('IVA:'),
                  Text(_printJob!.totalTax.formatToCurrency()),
                ],
              ),
            ],

            // IIBB
            if (_printJob!.iibbTax > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_printJob!.iibbTaxPercentage != null &&
                          _printJob!.iibbTaxPercentage! > 0
                      ? 'Percep. IIBB (${_printJob!.iibbTaxPercentage!.toStringAsFixed(1)}%):'
                      : 'Percep. IIBB:'),
                  Text(_printJob!.iibbTax.formatToCurrency()),
                ],
              ),
            ],

            // VAT Perception
            if (_printJob!.vatPerception > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Percep. IVA:'),
                  Text(_printJob!.vatPerception.formatToCurrency()),
                ],
              ),
            ],

            // Impuesto Interno
            if (_printJob!.internalTax > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_printJob!.internalTaxRate != null &&
                          _printJob!.internalTaxRate! > 0
                      ? 'Imp. Interno (${_printJob!.internalTaxRate!.toStringAsFixed(1)}%):'  
                      : 'Imp. Interno:'),
                  Text(_printJob!.internalTax.formatToCurrency()),
                ],
              ),
            ],

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(
                color: Colors.black,
                thickness: 2,
              ),
            ),
            if (widget.ticket.receivedAmount != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recibido:'),
                  Text(widget.ticket.receivedAmount!.formatToCurrency()),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Cambio:'),
                  Text(widget.ticket.change != null
                      ? widget.ticket.change!.formatToCurrency()
                      : '-'),
                ],
              ),
            ],

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTAL:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  widget.ticket.total.formatToCurrency(),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(
                color: Colors.black,
                thickness: 2,
              ),
            ),

            const SizedBox(height: 8),

            // Información adicional
            Text('Método de pago: $_paymentMethodName'),
            Text(
                'Total de artículos: ${widget.ticket.items?.fold(0, (previousValue, element) => previousValue + (element.quantity ?? 0)) ?? 0}'),

            const SizedBox(height: 16),
            const Center(
              child: Text(
                '¡Gracias por su compra!',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculatePriceWithTax(double price, double? taxPercentage) {
    final tax = (taxPercentage ?? 0.0) / 100;
    return price * (1 + tax);
  }
}
