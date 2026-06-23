import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/features/pos/domain/entities/cart_item.dart';
import 'package:punto_venta_app/features/pos/domain/entities/cart_log_entry.dart';
import 'package:punto_venta_app/features/pos/domain/entities/payment_method.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/fetch_return_reasons_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/calculate_order_taxes_usecase.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_state.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/clients/clients_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/clients/clients_state.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/checkout/checkout_event.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/confirmation/confirmation_helpers.dart';
import 'checkout_confirmation_state.dart';

class CheckoutConfirmationCubit extends Cubit<CheckoutConfirmationState> {
  final FetchReturnReasonsUsecase fetchReturnReasonsUsecase;
  final CalculateOrderTaxesUseCase calculateOrderTaxesUseCase;
  final CartBloc cartBloc;
  final ClientsBloc clientsBloc;

  late final StreamSubscription _cartSubscription;
  late final StreamSubscription _clientsSubscription;

  CheckoutConfirmationCubit({
    required this.fetchReturnReasonsUsecase,
    required this.calculateOrderTaxesUseCase,
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

      // 2. Calculate taxes using injected UseCase
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
    final selectedClient =
        clientsState is ClientsLoaded ? clientsState.selectedClient : null;

    final taxResult = await calculateOrderTaxesUseCase(
      items: cartLoaded.items,
      subtotal: cartLoaded.subtotal,
      totalIva: cartLoaded.totalIva,
      client: selectedClient,
    );

    List<PaymentMethod> updatedPayments = List<PaymentMethod>.from(state.selectedPayments);
    if (updatedPayments.isEmpty && defaultPaymentMethod != null) {
      updatedPayments = [defaultPaymentMethod.copyWith(amount: taxResult.totalAmount)];
    } else if (updatedPayments.length == 1) {
      updatedPayments[0] = updatedPayments[0].copyWith(amount: taxResult.totalAmount);
    }

    final result = calculateChangeAndAmounts(updatedPayments, taxResult.totalAmount);

    emit(state.copyWith(
      isLoading: false,
      iibbAmount: taxResult.iibbAmount,
      vatPerceptionAmount: taxResult.vatPerceptionAmount,
      internalTaxAmount: taxResult.internalTaxAmount,
      totalAmount: taxResult.totalAmount,
      selectedPayments: updatedPayments,
      receivedAmount: result.receivedAmount,
      change: result.change,
    ));
  }

  ProcessSale buildProcessSaleEvent({PaymentMethod? fallbackPaymentMethod}) {
    final cartState = cartBloc.state;
    final clientsState = clientsBloc.state;

    final items = cartState is CartLoaded ? cartState.items : const <CartItem>[];
    final logItems = cartState is CartLoaded ? cartState.log : const <CartLogEntry>[];
    final total = cartState is CartLoaded ? cartState.total : 0.0;
    final totalIva = cartState is CartLoaded ? cartState.totalIva : 0.0;
    final subtotal = cartState is CartLoaded ? cartState.subtotal : 0.0;

    final selectedClient =
        clientsState is ClientsLoaded ? clientsState.selectedClient : null;

    return ProcessSale(
      items: items,
      logItems: logItems,
      total: total,
      totalIva: totalIva,
      subtotal: subtotal,
      client: selectedClient,
      paymentMethod: state.selectedPayments.isNotEmpty
          ? state.selectedPayments.first
          : fallbackPaymentMethod,
      paymentMethods: state.selectedPayments.isNotEmpty
          ? state.selectedPayments
          : null,
      receivedAmount: state.receivedAmount,
      change: state.change,
    );
  }

  ConfirmReturn buildConfirmReturnEvent() {
    final cartState = cartBloc.state;
    final items = cartState is CartLoaded ? cartState.items : const <CartItem>[];
    final logItems = cartState is CartLoaded ? cartState.log : const <CartLogEntry>[];

    return ConfirmReturn(
      reasonId: state.selectedReturnReasonId ?? -1,
      items: items,
      logItems: logItems,
    );
  }

  @override
  Future<void> close() {
    _cartSubscription.cancel();
    _clientsSubscription.cancel();
    return super.close();
  }
}
