import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/constants/ticket_template_types.dart';
import 'package:punto_venta_app/features/auth/data/datasources/auth_local_datasources.dart';
import 'package:punto_venta_app/features/pos/data/datasources/pdv_local_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/price_list_local_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/branch_local_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/vat_category_local_datasource.dart';
import 'package:punto_venta_app/features/pos/data/models/vat_category_model.dart';
import 'package:punto_venta_app/features/pos/domain/entities/fiscal_issuer_data.dart';
import 'package:punto_venta_app/features/pos/domain/entities/print_job.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/fiscal_issuer_data_repository.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/complete_order_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/get_ticket_config_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/send_invoice_usecase.dart';
import 'package:punto_venta_app/features/pos/presentation/utils/iibb_calculator.dart';
import 'package:punto_venta_app/features/pos/presentation/utils/vat_perception_calculator.dart';
import 'package:punto_venta_app/features/pos/presentation/utils/internal_tax_calculator.dart';
import 'package:punto_venta_app/features/pos/presentation/utils/ticket_template_resolver.dart';
import 'checkout_event.dart';
import 'checkout_state.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/process_partial_return_usecase.dart';
import 'package:punto_venta_app/features/pos/data/models/partial_return_request_model.dart';

class CheckoutBloc extends Bloc<CheckoutEvent, CheckoutState> {
  final AuthLocalDataSource authLocalDataSource;
  final PdvLocalDataSource pdvLocalDataSource;
  final PriceListLocalDataSource priceListLocalDataSource;
  final BranchLocalDataSource branchLocalDataSource;
  final VatCategoryLocalDataSource vatCategoryLocalDataSource;
  final FiscalIssuerDataRepository fiscalIssuerDataRepository;
  final CompleteOrderUsecase completeOrderUsecase;
  final GetTicketConfigUsecase getTicketConfigUsecase;
  final SendInvoiceUseCase sendInvoiceUseCase;
  final ProcessPartialReturnUseCase processPartialReturnUseCase;

  CheckoutBloc({
    required this.authLocalDataSource,
    required this.pdvLocalDataSource,
    required this.priceListLocalDataSource,
    required this.branchLocalDataSource,
    required this.vatCategoryLocalDataSource,
    required this.fiscalIssuerDataRepository,
    required this.completeOrderUsecase,
    required this.getTicketConfigUsecase,
    required this.sendInvoiceUseCase,
    required this.processPartialReturnUseCase,
  }) : super(const CheckoutInitial()) {
    on<ProcessSale>(_onProcessSale);
    on<ResetCheckout>(_onResetCheckout);
    on<ConfirmReturn>(_onConfirmReturn);
  }

  Future<void> _onProcessSale(
    ProcessSale event,
    Emitter<CheckoutState> emit,
  ) async {
    emit(const CheckoutProcessing());

    try {
      // Obtener datos necesarios
      final user = await authLocalDataSource.getCachedUser();
      final priceList = await priceListLocalDataSource.getCurrentPriceList();
      final enterprise = await authLocalDataSource.getCachedEnterprise();
      final config = await pdvLocalDataSource.getPdvConfig();

      // Validar número de sucursal
      final branchNumber = config?.branchNumber ?? '';

      // if (branchNumber == null || branchNumber.trim().isEmpty) {
      //   emit(const CheckoutError(
      //     message: 'Configure el número de sucursal antes de realizar cobros.',
      //   ));
      //   return;
      // }

      // Obtener información de la sucursal y categoría IVA para calcular IIBB
      final branch = config?.branchId != null
          ? await branchLocalDataSource.getBranchById(config!.branchId!)
          : null;

      final vatCategory = event.client?.vatCategoryId != null
          ? await _getVatCategoryById(event.client!.vatCategoryId!)
          : null;

      // Calcular IIBB con porcentaje
      final iibbResult = IibbCalculator.calculateIibbWithPercentage(
        client: event.client,
        branch: branch,
        vatCategory: vatCategory,
        subtotal: event.subtotal,
        totalWithVat: event.total,
      );

      final iibbAmount = iibbResult['amount'] ?? 0.0;
      final iibbPercentage = iibbResult['percentage'];

      // Calcular percepción de IVA
      final vatPerceptionResult =
          VatPerceptionCalculator.calculateVatPerceptionWithBreakdown(
        cartItems: event.items,
        branch: branch,
        vatCategory: vatCategory,
      );

      final vatPerceptionAmount = vatPerceptionResult['total'] ?? 0.0;
      final vatPerceptionByRateDouble =
          vatPerceptionResult['byPerception'] as Map<double, double>?;
      final vatPerceptionByRate = vatPerceptionByRateDouble?.map(
        (key, value) => MapEntry(key.toString(), value),
      );

      // Calcular impuesto interno
      final internalTaxResult = InternalTaxCalculator.calculateInternalTax(
        items: event.items,
      );

      final internalTaxAmount = internalTaxResult['total'] ?? 0.0;
      final internalTaxRate = internalTaxResult['rate'];

      final totalWithIibb =
          event.total + iibbAmount + vatPerceptionAmount + internalTaxAmount;

      // Determinar template automáticamente
      TicketTemplateType templateType = TicketTemplateType.standard;
      bool showSubtotalAndTax = false;
      bool showPricesWithTax = true;

      bool? clientTaxDetails;
      if (vatCategory != null) {
        clientTaxDetails = vatCategory.taxDetails;
      }

      templateType = TicketTemplateResolver.resolveTemplate(
        branchAfipAvailable: branch?.afipAvailable,
      );

      showPricesWithTax = TicketTemplateResolver.shouldShowPricesWithTax(
        templateType: templateType,
        clientTaxDetails: clientTaxDetails,
      );

      showSubtotalAndTax = TicketTemplateResolver.shouldShowSubtotalAndTax(
        templateType: templateType,
        clientTaxDetails: clientTaxDetails,
        hasClient: event.client != null,
      );

      // Obtener datos fiscales del emisor si es operación en blanco
      FiscalIssuerData? fiscalData;
      if (branch?.afipAvailable == true && config?.branchId != null) {
        try {
          fiscalData = await fiscalIssuerDataRepository
              .getFiscalIssuerData(config!.branchId!);
        } catch (e) {
          print('Error al obtener datos fiscales: $e');
        }
      }

      // Crear PrintJob (sin ticketId definitivo)
      final tempPrintJob = PrintJob(
        items: event.items,
        logItems: event.logItems,
        total: totalWithIibb,
        clientName: event.client?.name,
        client: event.client,
        priceListId: priceList,
        totalTax: event.totalIva,
        iibbTax: iibbAmount,
        iibbTaxPercentage: iibbPercentage,
        vatPerception: vatPerceptionAmount,
        vatPerceptionByRate: vatPerceptionByRate,
        internalTax: internalTaxAmount,
        internalTaxRate: internalTaxRate,
        paymentMethod: event.paymentMethod,
        paymentMethods: event.paymentMethods,
        cashierName: user?.name ?? 'Desconocido',
        cashierId: int.tryParse(user?.id ?? ''),
        timestamp: DateTime.now(),
        enterprise: enterprise,
        fiscalIssuerData: fiscalData,
        showSubtotalAndTax: showSubtotalAndTax,
        showPricesWithTax: showPricesWithTax,
        receivedAmount: event.receivedAmount,
        change: event.change,
        branchNumber: branchNumber,
        branchId: config?.branchId,
        templateType: templateType,
      );

      // Enviar factura y obtener ticketId y description
      final invoiceResponse = await sendInvoiceUseCase(tempPrintJob);

      final ticketId = invoiceResponse['ticketId'] ?? '';
      final description = invoiceResponse['description'];

      // PrintJob final con el ticketId y description
      final finalPrintJob = PrintJob(
        ticketId: ticketId,
        items: event.items,
        logItems: event.logItems,
        total: totalWithIibb,
        clientName: event.client?.name,
        client: event.client,
        priceListId: priceList,
        totalTax: event.totalIva,
        iibbTax: iibbAmount,
        iibbTaxPercentage: iibbPercentage,
        vatPerception: vatPerceptionAmount,
        vatPerceptionByRate: vatPerceptionByRate,
        internalTax: internalTaxAmount,
        internalTaxRate: internalTaxRate,
        paymentMethod: event.paymentMethod,
        paymentMethods: event.paymentMethods,
        cashierName: user?.name ?? 'Desconocido',
        cashierId: int.tryParse(user?.id ?? ''),
        timestamp: tempPrintJob.timestamp,
        enterprise: enterprise,
        fiscalIssuerData: fiscalData,
        showSubtotalAndTax: showSubtotalAndTax,
        showPricesWithTax: showPricesWithTax,
        receivedAmount: event.receivedAmount,
        change: event.change,
        branchNumber: branchNumber,
        branchId: config?.branchId,
        description: description,
        templateType: templateType,
      );

      await completeOrderUsecase.fromPrintJob(finalPrintJob);

      emit(CheckoutSuccess(printJob: finalPrintJob));
    } catch (e) {
      emit(CheckoutError(message: _extractErrorMessage(e)));
    }
  }

  Future<VatCategoryModel?> _getVatCategoryById(int vatCategoryId) async {
    final categories =
        await vatCategoryLocalDataSource.getCachedVatCategories();

    if (categories == null) {
      return null;
    }

    try {
      final found = categories.firstWhere((c) => c.id == vatCategoryId);
      return found;
    } catch (e) {
      return null;
    }
  }

  void _onResetCheckout(ResetCheckout event, Emitter<CheckoutState> emit) {
    emit(const CheckoutInitial());
  }

  String _extractErrorMessage(dynamic error) {
    String message = error.toString();
    while (message.startsWith('Exception: ')) {
      message = message.replaceFirst('Exception: ', '');
    }
    return message;
  }

  Future<void> _onConfirmReturn(
    ConfirmReturn event,
    Emitter<CheckoutState> emit,
  ) async {
    emit(const CheckoutProcessing());

    try {
      final config = await pdvLocalDataSource.getPdvConfig();
      final branchId = config?.branchId;
      final deliveryLocationId = config?.pdvId;

      if (branchId == null || deliveryLocationId == null) {
        emit(const CheckoutError(
          message:
              'Configure la sucursal y la ubicación antes de hacer devoluciones.',
        ));
        return;
      }

      final returnItems = event.items.map((item) {
        final double qty = (item.isWeighted == true)
            ? (item.weightKg ?? 0.0)
            : item.quantity.toDouble();
        return PartialReturnItemModel(
          articleId: item.product.id,
          quantity: qty,
        );
      }).toList();

      final request = PartialReturnRequestModel(
        reasonId: event.reasonId,
        branchId: branchId,
        deliveryLocationId: deliveryLocationId,
        items: returnItems,
      );

      final completedOrder = await processPartialReturnUseCase(request);

      if (completedOrder == null) {
        emit(const CheckoutError(
            message: 'Error al procesar la devolución. Intente nuevamente.'));
        return;
      }

      // Convertir completedOrder en un PrintJob
      final user = await authLocalDataSource.getCachedUser();
      final enterprise = await authLocalDataSource.getCachedEnterprise();

      FiscalIssuerData? fiscalData;
      if (completedOrder.branchId != null) {
        try {
          fiscalData = await fiscalIssuerDataRepository
              .getFiscalIssuerData(completedOrder.branchId!);
        } catch (e) {
          print('Error al obtener datos fiscales para devolución: $e');
        }
      }

      final printJob = PrintJob(
        ticketId: completedOrder.id,
        items: completedOrder.items,
        logItems: completedOrder.logs,
        total: completedOrder.total,
        clientName: completedOrder.clientName,
        client: completedOrder.client,
        priceListId: completedOrder.priceListId,
        totalTax: completedOrder.totalTax,
        iibbTax: completedOrder.iibbTax,
        iibbTaxPercentage: completedOrder.iibbTaxPercentage,
        vatPerception: completedOrder.vatPerception,
        vatPerceptionByRate: completedOrder.vatPerceptionByRate,
        internalTax: completedOrder.internalTax,
        internalTaxRate: completedOrder.internalTaxRate,
        paymentMethod: completedOrder.paymentMethod,
        paymentMethods: completedOrder.paymentMethods,
        cashierName: completedOrder.cashierName ?? user?.name ?? 'Desconocido',
        cashierId: completedOrder.cashierId ?? int.tryParse(user?.id ?? ''),
        timestamp: completedOrder.completedAt,
        enterprise: enterprise,
        fiscalIssuerData: fiscalData,
        showSubtotalAndTax: completedOrder.showSubtotalAndTax,
        showPricesWithTax: completedOrder.showPricesWithTax,
        receivedAmount: completedOrder.receivedAmount,
        change: completedOrder.change,
        branchNumber: completedOrder.branchNumber ?? '',
        branchId: completedOrder.branchId,
        description: completedOrder.description,
        templateType: completedOrder.templateType,
        isCreditNote: true,
      );

      emit(CheckoutSuccess(printJob: printJob));
    } catch (e) {
      emit(CheckoutError(message: _extractErrorMessage(e)));
    }
  }
}
