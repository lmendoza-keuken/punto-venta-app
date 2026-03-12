import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/features/auth/data/datasources/auth_local_datasources.dart';
import 'package:punto_venta_app/features/pos/data/datasources/pdv_local_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/price_list_local_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/branch_local_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/vat_category_local_datasource.dart';
import 'package:punto_venta_app/features/pos/domain/entities/print_job.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/complete_order_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/get_ticket_config_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/send_invoice_usecase.dart';
import 'package:punto_venta_app/features/pos/presentation/utils/iibb_calculator.dart';
import 'checkout_event.dart';
import 'checkout_state.dart';

class CheckoutBloc extends Bloc<CheckoutEvent, CheckoutState> {
  final AuthLocalDataSource authLocalDataSource;
  final PdvLocalDataSource pdvLocalDataSource;
  final PriceListLocalDataSource priceListLocalDataSource;
  final BranchLocalDataSource branchLocalDataSource;
  final VatCategoryLocalDataSource vatCategoryLocalDataSource;
  final CompleteOrderUsecase completeOrderUsecase;
  final GetTicketConfigUsecase getTicketConfigUsecase;
  final SendInvoiceUseCase sendInvoiceUseCase;

  CheckoutBloc({
    required this.authLocalDataSource,
    required this.pdvLocalDataSource,
    required this.priceListLocalDataSource,
    required this.branchLocalDataSource,
    required this.vatCategoryLocalDataSource,
    required this.completeOrderUsecase,
    required this.getTicketConfigUsecase,
    required this.sendInvoiceUseCase,
  }) : super(const CheckoutInitial()) {
    on<ProcessSale>(_onProcessSale);
    on<ResetCheckout>(_onResetCheckout);
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
      final appConfig = await getTicketConfigUsecase();

      // Validar número de sucursal
      final branchNumber = config?.branchNumber;
      if (branchNumber == null || branchNumber.trim().isEmpty) {
        emit(const CheckoutError(
          message: 'Configure el número de sucursal antes de realizar cobros.',
        ));
        return;
      }

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

      // Total final incluye IIBB
      final totalWithIibb = event.total + iibbAmount;

      // Configurar opciones de impresión
      bool showSubtotalAndTax = false;
      bool showPricesWithTax = true;

      if (appConfig != null) {
        if (appConfig.showSubtotalAndTax && event.client != null) {
          showSubtotalAndTax = true;
        }
        showPricesWithTax = appConfig.showPricesWithTax;
      }

      // Guardar orden completada
      await completeOrderUsecase(
        items: event.items,
        logItems: event.logItems,
        total: totalWithIibb,
        clientName: event.client?.name,
        paymentMethod: event.paymentMethod,
        cashierName: user?.name ?? 'Desconocido',
        showSubtotalAndTax: showSubtotalAndTax,
        showPricesWithTax: showPricesWithTax,
        receivedAmount: event.receivedAmount,
        change: event.change,
      );

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
        paymentMethod: event.paymentMethod,
        cashierName: user?.name ?? 'Desconocido',
        cashierId: int.tryParse(user?.id ?? ''),
        timestamp: DateTime.now(),
        enterprise: enterprise,
        showSubtotalAndTax: showSubtotalAndTax,
        showPricesWithTax: showPricesWithTax,
        receivedAmount: event.receivedAmount,
        change: event.change,
        branchNumber: branchNumber,
        branchId: config?.branchId,
      );

      // Enviar factura y obtener ticketId
      final ticketId = await sendInvoiceUseCase(tempPrintJob);

      // PrintJob final con el ticketId
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
        paymentMethod: event.paymentMethod,
        cashierName: user?.name ?? 'Desconocido',
        cashierId: int.tryParse(user?.id ?? ''),
        timestamp: tempPrintJob.timestamp,
        enterprise: enterprise,
        showSubtotalAndTax: showSubtotalAndTax,
        showPricesWithTax: showPricesWithTax,
        receivedAmount: event.receivedAmount,
        change: event.change,
        branchNumber: branchNumber,
        branchId: config?.branchId,
      );

      emit(CheckoutSuccess(printJob: finalPrintJob));
    } catch (e) {
      emit(CheckoutError(message: _extractErrorMessage(e)));
    }
  }

  Future<dynamic> _getVatCategoryById(int vatCategoryId) async {
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
}
