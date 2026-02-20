import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/fetch_payment_methods_usecase.dart';
import 'payment_methods_event.dart';
import 'payment_methods_state.dart';

class PaymentMethodsBloc
    extends Bloc<PaymentMethodsEvent, PaymentMethodsState> {
  final FetchPaymentMethodsUsecase fetchPaymentMethods;

  PaymentMethodsBloc({
    required this.fetchPaymentMethods,
  }) : super(PaymentMethodsInitial()) {
    on<LoadPaymentMethods>(_onLoadPaymentMethods);
    on<SelectPaymentMethodEvent>(_onSelectPaymentMethod);
  }

  Future<void> _onLoadPaymentMethods(
      LoadPaymentMethods event, Emitter<PaymentMethodsState> emit) async {
    final currentState = state;
    final currentSelectedPaymentMethod = currentState is PaymentMethodsLoaded
        ? currentState.selectedPaymentMethod
        : null;

    emit(PaymentMethodsLoading());
    try {
      final paymentMethods = await fetchPaymentMethods();

      var selectedPaymentMethod = currentSelectedPaymentMethod;
      if (selectedPaymentMethod == null && paymentMethods.isNotEmpty) {
        selectedPaymentMethod = paymentMethods.firstWhere(
          (pm) =>
              pm.description.toLowerCase().contains('pagos en efectivo') ||
              pm.shortDescription.toLowerCase().contains('efectivo'),
          orElse: () => paymentMethods.first,
        );
      }

      emit(PaymentMethodsLoaded(
        paymentMethods: paymentMethods,
        selectedPaymentMethod: selectedPaymentMethod,
      ));
    } catch (e) {
      emit(PaymentMethodsError(e.toString()));
    }
  }

  void _onSelectPaymentMethod(
      SelectPaymentMethodEvent event, Emitter<PaymentMethodsState> emit) {
    final current = state;
    if (current is PaymentMethodsLoaded) {
      emit(PaymentMethodsLoaded(
          paymentMethods: current.paymentMethods,
          selectedPaymentMethod: event.paymentMethod));
    } else {
      emit(PaymentMethodsLoaded(
          paymentMethods: [], selectedPaymentMethod: event.paymentMethod));
    }
  }
}
