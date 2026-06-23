import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/features/pos/data/datasources/pdv_local_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/branch_local_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/vat_category_local_datasource.dart';
import 'package:punto_venta_app/features/pos/domain/entities/payment_method.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/fetch_return_reasons_usecase.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_state.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/clients/clients_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/clients/clients_state.dart';
import 'package:punto_venta_app/features/pos/presentation/utils/iibb_calculator.dart';
import 'package:punto_venta_app/features/pos/presentation/utils/vat_perception_calculator.dart';
import 'package:punto_venta_app/features/pos/presentation/utils/internal_tax_calculator.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/confirmation/confirmation_helpers.dart';
import 'checkout_confirmation_state.dart';

class CheckoutConfirmationCubit extends Cubit<CheckoutConfirmationState> {
  final FetchReturnReasonsUsecase fetchReturnReasonsUsecase;
  final PdvLocalDataSource pdvLocalDataSource;
  final BranchLocalDataSource branchLocalDataSource;
  final VatCategoryLocalDataSource vatCategoryLocalDataSource;
  final CartBloc cartBloc;
  final ClientsBloc clientsBloc;

  late final StreamSubscription _cartSubscription;
  late final StreamSubscription _clientsSubscription;

  CheckoutConfirmationCubit({
    required this.fetchReturnReasonsUsecase,
    required this.pdvLocalDataSource,
    required this.branchLocalDataSource,
    required this.vatCategoryLocalDataSource,
    required this.cartBloc,
    required this.clientsBloc,
  }) : super(const CheckoutConfirmationState()) {
    _cartSubscription = cartBloc.stream.listen((cartState) {
      _calculateTaxes(cartState, clientsBloc.state);
    });

    _clientsSubscription = clientsBloc.stream.listen((clientsState) {
      _calculateTaxes(cartBloc.state, clientsState);
    });
  }

  Future<void> load(PaymentMethod? defaultPaymentMethod) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      // 1. Fetch return reasons
      final reasons = await fetchReturnReasonsUsecase();
      final defaultReasonId = reasons.isNotEmpty ? reasons.first.id : null;

      emit(state.copyWith(
        returnReasons: reasons,
        selectedReturnReasonId: defaultReasonId,
      ));

      // 2. Calculate taxes using injected blocs
      await _calculateTaxes(cartBloc.state, clientsBloc.state, defaultPaymentMethod: defaultPaymentMethod);
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  void selectReturnReason(int reasonId) {
    emit(state.copyWith(selectedReturnReasonId: reasonId));
  }

  void initializePayments(PaymentMethod? defaultPaymentMethod, double totalAmount) {
    if (state.selectedPayments.isNotEmpty) return;
    if (defaultPaymentMethod != null) {
      final payments = [defaultPaymentMethod.copyWith(amount: totalAmount)];
      final result = calculateChangeAndAmounts(payments, totalAmount);
      emit(state.copyWith(
        selectedPayments: payments,
        receivedAmount: result.receivedAmount,
        change: result.change,
      ));
    }
  }

  void selectSinglePaymentMethod(PaymentMethod method, double totalAmount) {
    if (state.selectedPayments.isEmpty ||
        (state.selectedPayments.length == 1 && state.selectedPayments.first.id != method.id)) {
      final payments = [method.copyWith(amount: totalAmount)];
      final result = calculateChangeAndAmounts(payments, totalAmount);
      emit(state.copyWith(
        selectedPayments: payments,
        receivedAmount: result.receivedAmount,
        change: result.change,
      ));
    }
  }

  void addPaymentMethod(PaymentMethod method, double defaultAmount, double totalAmount) {
    final updated = List<PaymentMethod>.from(state.selectedPayments);
    updated.add(method.copyWith(amount: defaultAmount));
    final result = calculateChangeAndAmounts(updated, totalAmount);
    emit(state.copyWith(
      selectedPayments: updated,
      receivedAmount: result.receivedAmount,
      change: result.change,
    ));
  }

  void removePaymentMethod(int index, double totalAmount) {
    if (index >= state.selectedPayments.length) return;
    final updated = List<PaymentMethod>.from(state.selectedPayments);
    updated.removeAt(index);

    if (updated.length == 1) {
      updated[0] = updated[0].copyWith(amount: totalAmount);
    }

    final result = calculateChangeAndAmounts(updated, totalAmount);
    emit(state.copyWith(
      selectedPayments: updated,
      receivedAmount: result.receivedAmount,
      change: result.change,
    ));
  }

  void updatePaymentAmount(int index, double amount, double totalAmount) {
    if (index >= state.selectedPayments.length) return;
    final updated = List<PaymentMethod>.from(state.selectedPayments);
    updated[index] = updated[index].copyWith(amount: amount);

    final result = calculateChangeAndAmounts(updated, totalAmount);
    emit(state.copyWith(
      selectedPayments: updated,
      receivedAmount: result.receivedAmount,
      change: result.change,
    ));
  }

  void updatePaymentReceivedAmount(int index, double? receivedAmount, double totalAmount) {
    if (index >= state.selectedPayments.length) return;
    final updated = List<PaymentMethod>.from(state.selectedPayments);
    updated[index] = updated[index].copyWith(receivedAmount: receivedAmount);

    final result = calculateChangeAndAmounts(updated, totalAmount);
    emit(state.copyWith(
      selectedPayments: updated,
      receivedAmount: result.receivedAmount,
      change: result.change,
    ));
  }

  void updatePaymentDetails(int index, PaymentMethodDetails details) {
    if (index >= state.selectedPayments.length) return;
    final updated = List<PaymentMethod>.from(state.selectedPayments);
    updated[index] = updated[index].copyWith(details: details);

    emit(state.copyWith(
      selectedPayments: updated,
    ));
  }

  Future<void> _calculateTaxes(
    CartState cartState,
    ClientsState clientsState, {
    PaymentMethod? defaultPaymentMethod,
  }) async {
    if (cartState is! CartLoaded) {
      emit(state.copyWith(
        isLoading: false,
        iibbAmount: 0.0,
        vatPerceptionAmount: 0.0,
        internalTaxAmount: 0.0,
        totalAmount: 0.0,
      ));
      return;
    }

    final cartLoaded = cartState;
    final internalTaxResult = InternalTaxCalculator.calculateInternalTax(
      items: cartLoaded.items,
    );
    final double computedInternalTax = internalTaxResult['total'] ?? 0.0;

    final selectedClient =
        clientsState is ClientsLoaded ? clientsState.selectedClient : null;

    double iibb = 0.0;
    double vatPerception = 0.0;

    if (selectedClient != null) {
      try {
        final pdvConfig = await pdvLocalDataSource.getPdvConfig();
        final branchId = pdvConfig?.branchId;

        if (branchId != null) {
          final branch = await branchLocalDataSource.getBranchById(branchId);
          final vatCategoryId = selectedClient.vatCategoryId;
          final allVatCategories = await vatCategoryLocalDataSource.getCachedVatCategories();
          final vatCategory =
              allVatCategories?.where((cat) => cat.id == vatCategoryId).firstOrNull;

          iibb = IibbCalculator.calculateIibb(
            client: selectedClient,
            branch: branch,
            vatCategory: vatCategory,
            subtotal: cartLoaded.subtotal,
            totalWithVat: cartLoaded.subtotal + cartLoaded.totalIva,
          );

          vatPerception = VatPerceptionCalculator.calculateVatPerception(
            cartItems: cartLoaded.items,
            branch: branch,
            vatCategory: vatCategory,
          );
        }
      } catch (e) {
        // Keep logs / handle errors
      }
    }

    final totalAmount = cartLoaded.subtotal +
        cartLoaded.totalIva +
        iibb +
        vatPerception +
        computedInternalTax;

    List<PaymentMethod> updatedPayments = List<PaymentMethod>.from(state.selectedPayments);
    if (updatedPayments.isEmpty && defaultPaymentMethod != null) {
      updatedPayments = [defaultPaymentMethod.copyWith(amount: totalAmount)];
    } else if (updatedPayments.length == 1) {
      updatedPayments[0] = updatedPayments[0].copyWith(amount: totalAmount);
    }

    final result = calculateChangeAndAmounts(updatedPayments, totalAmount);

    emit(state.copyWith(
      isLoading: false,
      iibbAmount: iibb,
      vatPerceptionAmount: vatPerception,
      internalTaxAmount: computedInternalTax,
      totalAmount: totalAmount,
      selectedPayments: updatedPayments,
      receivedAmount: result.receivedAmount,
      change: result.change,
    ));
  }

  @override
  Future<void> close() {
    _cartSubscription.cancel();
    _clientsSubscription.cancel();
    return super.close();
  }
}
