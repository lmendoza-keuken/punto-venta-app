import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/utils/confirm_sale_flow_logger.dart';
import 'package:punto_venta_app/features/pos/domain/entities/cart_item.dart';
import 'package:punto_venta_app/features/pos/domain/entities/cart_log_entry.dart';
import 'package:punto_venta_app/features/pos/domain/entities/payment_method.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/fetch_return_reasons_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/fetch_dispose_reasons_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/calculate_order_taxes_usecase.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_state.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/clients/clients_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/clients/clients_state.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/checkout/checkout_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_state.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/confirmation/confirmation_helpers.dart';
import 'package:punto_venta_app/features/pos/domain/entities/pdv_config.dart';
import 'package:punto_venta_app/features/pos/domain/entities/payment_method_config.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/fetch_branches_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/fetch_payment_methods_config_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/fetch_pdv_config_usecase.dart';
import 'package:punto_venta_app/features/pos/data/datasources/pdv_local_datasource.dart';
import 'package:punto_venta_app/injection_container.dart' as di;
import 'checkout_confirmation_state.dart';

class CheckoutConfirmationCubit extends Cubit<CheckoutConfirmationState> {
  final FetchReturnReasonsUsecase fetchReturnReasonsUsecase;
  final FetchDisposeReasonsUsecase fetchDisposeReasonsUsecase;
  final CalculateOrderTaxesUseCase calculateOrderTaxesUseCase;
  final CartBloc cartBloc;
  final ClientsBloc clientsBloc;

  late final StreamSubscription _cartSubscription;
  late final StreamSubscription _clientsSubscription;

  List<Branch> _allBranches = [];
  PaymentMethodsConfig? _paymentMethodsConfig;
  PdvConfig? _pdvConfig;
  CartMode _cartMode = CartMode.sale;

  /// Cuando el usuario edita un método secundario, se bloquea el auto-balance.
  /// Sigue permitido completar el restante al editar el primer método o al agregar.
  bool _paymentDistributionLocked = false;

  CheckoutConfirmationCubit({
    required this.fetchReturnReasonsUsecase,
    required this.fetchDisposeReasonsUsecase,
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

  Future<void> load(
    PaymentMethod? defaultPaymentMethod, {
    CartMode cartMode = CartMode.sale,
  }) async {
    _cartMode = cartMode;
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      if (cartMode == CartMode.returnMode) {
        final reasons = await fetchReturnReasonsUsecase();
        emit(state.copyWith(
          returnReasons: reasons,
          selectedReturnReasonId:
              reasons.isNotEmpty ? reasons.first.id : null,
        ));
      } else if (cartMode == CartMode.disposeMode) {
        final reasons = await fetchDisposeReasonsUsecase();
        emit(state.copyWith(
          disposeReasons: reasons,
          selectedDisposeReasonId:
              reasons.isNotEmpty ? reasons.first.id : null,
        ));
      }

      _allBranches = await di.sl<FetchBranchesUsecase>()();
      _paymentMethodsConfig = await di.sl<FetchPaymentMethodsConfigUsecase>()();
      try {
        _pdvConfig = await di.sl<FetchPdvConfigUsecase>()();
      } catch (_) {
        _pdvConfig = await di.sl<PdvLocalDataSource>().getPdvConfig();
      }

      await _calculateTaxes(cartBloc.state, clientsBloc.state,
          defaultPaymentMethod: defaultPaymentMethod);
      _updateActiveBranch();
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

  void selectDisposeReason(int reasonId) {
    emit(state.copyWith(selectedDisposeReasonId: reasonId));
  }

  void initializePayments(
      PaymentMethod? defaultPaymentMethod, double totalAmount) {
    if (state.selectedPayments.isNotEmpty) return;
    if (defaultPaymentMethod != null) {
      final payments = [defaultPaymentMethod.copyWith(amount: totalAmount)];
      final result = calculateChangeAndAmounts(payments, totalAmount);
      emit(state.copyWith(
        selectedPayments: payments,
        receivedAmount: result.receivedAmount,
        change: result.change,
      ));
      _updateActiveBranch();
    }
  }

  void selectSinglePaymentMethod(PaymentMethod method, double totalAmount) {
    if (state.selectedPayments.isEmpty ||
        (state.selectedPayments.length == 1 &&
            state.selectedPayments.first.id != method.id)) {
      final payments = [method.copyWith(amount: totalAmount)];
      final result = calculateChangeAndAmounts(payments, totalAmount);
      _paymentDistributionLocked = false;
      emit(state.copyWith(
        selectedPayments: payments,
        receivedAmount: result.receivedAmount,
        change: result.change,
        // Al cambiar de método de pago único, forzamos a recalcular la sucursal por defecto
        resetActiveBranch: true,
      ));
      _updateActiveBranch();
    }
  }

  void addPaymentMethod(
      PaymentMethod method, double defaultAmount, double totalAmount) {
    final updated = List<PaymentMethod>.from(state.selectedPayments);
    final allocated =
        updated.fold<double>(0.0, (sum, pm) => sum + (pm.amount ?? 0.0));
    final remaining =
        double.parse((totalAmount - allocated).toStringAsFixed(2));
    // Precarga: el nuevo método recibe el restante por cobrar.
    final preloadAmount = remaining > 0 ? remaining : defaultAmount;
    updated.add(method.copyWith(
      amount: preloadAmount > 0 ? preloadAmount : 0.0,
    ));
    // Al agregar, se permite completar el restante si aún se edita el 1er método.
    _paymentDistributionLocked = false;
    // Efectivo no edita monto: siempre absorbe el remanente.
    _syncCashAmountsToRemaining(updated, totalAmount);
    final result = calculateChangeAndAmounts(updated, totalAmount);
    emit(state.copyWith(
      selectedPayments: updated,
      receivedAmount: result.receivedAmount,
      change: result.change,
    ));
    _updateActiveBranch();
  }

  void removePaymentMethod(int index, double totalAmount) {
    if (index >= state.selectedPayments.length) return;
    final updated = List<PaymentMethod>.from(state.selectedPayments);
    updated.removeAt(index);

    if (updated.length == 1) {
      updated[0] = updated[0].copyWith(amount: totalAmount);
      _paymentDistributionLocked = false;
    } else {
      _syncCashAmountsToRemaining(updated, totalAmount);
    }

    final result = calculateChangeAndAmounts(updated, totalAmount);
    emit(state.copyWith(
      selectedPayments: updated,
      receivedAmount: result.receivedAmount,
      change: result.change,
      // Si volvemos a un único método de pago, forzamos a recalcular la sucursal por defecto
      resetActiveBranch: updated.length == 1,
    ));
    _updateActiveBranch();
  }

  void updatePaymentAmount(int index, double amount, double totalAmount) {
    if (index >= state.selectedPayments.length) return;
    // Efectivo no tiene monto editable; su amount es el remanente.
    if (_isCashMethod(state.selectedPayments[index])) return;

    final updated = List<PaymentMethod>.from(state.selectedPayments);
    updated[index] = updated[index].copyWith(amount: amount);

    // Si el usuario edita un método secundario, bloquea el auto-balance.
    if (index > 0) {
      _paymentDistributionLocked = true;
    } else if (!_paymentDistributionLocked && updated.length > 1) {
      // Editar el primero (aún sin tocar el segundo): completa el restante.
      _rebalanceRemainingAmount(updated, index, totalAmount);
    }

    // Efectivo siempre toma el remanente para el vuelto genérico.
    _syncCashAmountsToRemaining(updated, totalAmount);

    final result = calculateChangeAndAmounts(updated, totalAmount);
    emit(state.copyWith(
      selectedPayments: updated,
      receivedAmount: result.receivedAmount,
      change: result.change,
    ));
  }

  void updatePaymentReceivedAmount(
      int index, double? receivedAmount, double totalAmount) {
    if (index >= state.selectedPayments.length) return;
    final updated = List<PaymentMethod>.from(state.selectedPayments);
    final pm = updated[index];
    final isCash = _isCashMethod(pm);

    // En un solo método (efectivo), el amount sigue al recibido (tope = total)
    // para que al agregar otro método la precarga del restante funcione.
    // Con varios métodos, el amount de efectivo es el remanente (no el recibido).
    double? newAmount = pm.amount;
    if (isCash && updated.length == 1) {
      if (receivedAmount == null) {
        newAmount = 0.0;
      } else {
        newAmount =
            receivedAmount < totalAmount ? receivedAmount : totalAmount;
      }
    }

    updated[index] = updated[index].copyWith(
      amount: newAmount,
      receivedAmount: receivedAmount,
      clearReceivedAmount: receivedAmount == null,
    );

    if (isCash && updated.length > 1) {
      _syncCashAmountsToRemaining(updated, totalAmount);
    }

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

  bool _isCashMethod(PaymentMethod pm) {
    return pm.description.toLowerCase().contains('efectivo') ||
        pm.shortDescription.toLowerCase().contains('efectivo');
  }

  /// Efectivo no edita "monto a pagar": su amount es siempre el remanente
  /// respecto de los demás métodos, para calcular vuelto = paga con − amount.
  void _syncCashAmountsToRemaining(
      List<PaymentMethod> updated, double totalAmount) {
    if (updated.length <= 1) return;

    double nonCashSum = 0.0;
    final cashIndexes = <int>[];
    for (int i = 0; i < updated.length; i++) {
      if (_isCashMethod(updated[i])) {
        cashIndexes.add(i);
      } else {
        nonCashSum += updated[i].amount ?? 0.0;
      }
    }
    if (cashIndexes.isEmpty) return;

    double remaining =
        double.parse((totalAmount - nonCashSum).toStringAsFixed(2));
    if (remaining < 0.0) remaining = 0.0;

    for (int k = 0; k < cashIndexes.length; k++) {
      final i = cashIndexes[k];
      final amount = k == 0 ? remaining : 0.0;
      updated[i] = updated[i].copyWith(amount: amount);
    }
  }

  void _rebalanceRemainingAmount(
      List<PaymentMethod> updated, int sourceIndex, double totalAmount) {
    if (updated.length <= 1) return;

    final targetIndex = (sourceIndex + 1) % updated.length;
    // Si el destino es efectivo, _syncCashAmountsToRemaining lo ajusta después.
    if (_isCashMethod(updated[targetIndex])) return;

    double sumOthers = 0.0;
    for (int j = 0; j < updated.length; j++) {
      if (j != targetIndex) {
        sumOthers += updated[j].amount ?? 0.0;
      }
    }
    double remaining = totalAmount - sumOthers;
    if (remaining < 0.0) remaining = 0.0;

    final targetPm = updated[targetIndex];
    updated[targetIndex] = targetPm.copyWith(
      amount: double.parse(remaining.toStringAsFixed(2)),
    );
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

    List<PaymentMethod> updatedPayments =
        List<PaymentMethod>.from(state.selectedPayments);
    if (updatedPayments.isEmpty && defaultPaymentMethod != null) {
      updatedPayments = [
        defaultPaymentMethod.copyWith(amount: taxResult.totalAmount)
      ];
    } else if (updatedPayments.length == 1) {
      updatedPayments[0] =
          updatedPayments[0].copyWith(amount: taxResult.totalAmount);
    }

    final result =
        calculateChangeAndAmounts(updatedPayments, taxResult.totalAmount);

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
    _updateActiveBranch();
  }

  ProcessSale buildProcessSaleEvent({PaymentMethod? fallbackPaymentMethod}) {
    ConfirmSaleFlowLog.step('map_process_sale_event_start');
    final cartState = cartBloc.state;
    final clientsState = clientsBloc.state;

    final items =
        cartState is CartLoaded ? cartState.items : const <CartItem>[];
    final logItems =
        cartState is CartLoaded ? cartState.log : const <CartLogEntry>[];
    final total = cartState is CartLoaded ? cartState.total : 0.0;
    final totalIva = cartState is CartLoaded ? cartState.totalIva : 0.0;
    final subtotal = cartState is CartLoaded ? cartState.subtotal : 0.0;

    final selectedClient =
        clientsState is ClientsLoaded ? clientsState.selectedClient : null;

    final event = ProcessSale(
      items: items,
      logItems: logItems,
      total: total,
      totalIva: totalIva,
      subtotal: subtotal,
      client: selectedClient,
      paymentMethod: state.selectedPayments.isNotEmpty
          ? state.selectedPayments.first
          : fallbackPaymentMethod,
      paymentMethods:
          state.selectedPayments.isNotEmpty ? state.selectedPayments : null,
      receivedAmount: state.receivedAmount,
      change: state.change,
      branchId: state.activeBranchId,
    );
    ConfirmSaleFlowLog.step(
      'map_process_sale_event_done',
      detail:
          'items=${items.length} logItems=${logItems.length} '
          'subtotal=$subtotal total=$total totalIva=$totalIva '
          'clientId=${selectedClient?.id} '
          'payments=${event.paymentMethods?.length ?? 0} '
          'received=${state.receivedAmount} change=${state.change} '
          'branchId=${state.activeBranchId}',
    );
    return event;
  }

  void selectBranch(int branchId) {
    final branch = _allBranches.firstWhere(
      (b) => b.id == branchId,
      orElse: () => const Branch(
          id: -1,
          name: '',
          afipAvailable: false,
          applyPerIibb: false,
          applyPerVat: false),
    );
    if (branch.id != -1) {
      emit(state.copyWith(
        activeBranchId: branchId,
        activeBranchName: branch.name,
      ));
    }
  }

  bool get _isNonDefaultClient {
    final clientsState = clientsBloc.state;
    if (clientsState is! ClientsLoaded) return false;
    final selected = clientsState.selectedClient;
    final defaultClient = clientsState.defaultClient;
    if (selected == null || defaultClient == null) return false;
    return selected.id != defaultClient.id;
  }

  void _emitActiveBranch({
    required int? activeBranchId,
    required List<Branch> allowedBranches,
  }) {
    String? activeBranchName;
    if (activeBranchId != null) {
      final activeBranch = _allBranches.firstWhere(
        (b) => b.id == activeBranchId,
        orElse: () => const Branch(
            id: -1,
            name: '',
            afipAvailable: false,
            applyPerIibb: false,
            applyPerVat: false),
      );
      if (activeBranch.id != -1) {
        activeBranchName = activeBranch.name;
      }
    }

    emit(state.copyWith(
      activeBranchId: activeBranchId,
      activeBranchName: activeBranchName,
      allowedBranches: allowedBranches,
    ));
  }

  void _updateActiveBranch() {
    if (_allBranches.isEmpty || _pdvConfig == null) return;

    // Cliente distinto al default: solo la sucursal configurada para otros clientes.
    if (_isNonDefaultClient) {
      final forcedBranchId =
          _pdvConfig?.nonDefaultClientBranchId ?? _pdvConfig?.branchId;
      final forcedBranch = _allBranches.firstWhere(
        (b) => b.id == forcedBranchId,
        orElse: () => const Branch(
            id: -1,
            name: '',
            afipAvailable: false,
            applyPerIibb: false,
            applyPerVat: false),
      );

      if (forcedBranch.id != -1) {
        _emitActiveBranch(
          activeBranchId: forcedBranch.id,
          allowedBranches: [forcedBranch],
        );
      } else {
        _emitActiveBranch(
          activeBranchId: forcedBranchId,
          allowedBranches: const [],
        );
      }
      return;
    }

    final payments = state.selectedPayments;
    int? activeBranchId;
    List<Branch> allowedBranches = [];

    // Si es devolución o no hay métodos de pago seleccionados, permitimos seleccionar todas las sucursales, seleccionando por defecto la del PDV
    if (_cartMode != CartMode.sale || payments.isEmpty) {
      allowedBranches = List<Branch>.from(_allBranches);
      if (state.activeBranchId != null &&
          allowedBranches.any((b) => b.id == state.activeBranchId)) {
        activeBranchId = state.activeBranchId;
      } else {
        activeBranchId = _pdvConfig?.branchId;
      }
    } else {
      // 1. Obtener la prioridad mínima más alta entre los métodos elegidos
      int maxMinPriority = 0;
      for (final payment in payments) {
        final pmConfig = _paymentMethodsConfig?.paymentMethodsConfig.firstWhere(
          (c) => c.paymentMethodId == payment.id,
          orElse: () => const PaymentMethodConfig(
              paymentMethodId: -1, branchesSelected: []),
        );
        if (pmConfig != null &&
            pmConfig.paymentMethodId != -1 &&
            pmConfig.minBranchPriority != null) {
          if (pmConfig.minBranchPriority! > maxMinPriority) {
            maxMinPriority = pmConfig.minBranchPriority!;
          }
        }
      }

      // 2. Calcular la intersección de sucursales habilitadas que cumplan con la condición de prioridad mínima
      // Los métodos de pago con una prioridad mínima menor que el máximo requerido no restringen la selección.
      Set<int>? commonBranchIds;

      for (final payment in payments) {
        final pmConfig = _paymentMethodsConfig?.paymentMethodsConfig.firstWhere(
          (c) => c.paymentMethodId == payment.id,
          orElse: () => const PaymentMethodConfig(
              paymentMethodId: -1, branchesSelected: []),
        );

        final pmPriority = pmConfig?.minBranchPriority ?? 0;
        if (pmPriority < maxMinPriority) {
          continue;
        }

        final Set<int> allowedForMethod = {};

        if (pmConfig != null && pmConfig.paymentMethodId != -1) {
          // Si tiene sucursales explícitas configuradas
          if (pmConfig.branchesSelected.isNotEmpty) {
            final validBranches = pmConfig.branchesSelected.where((branchId) {
              final branch = _allBranches.firstWhere(
                (b) => b.id == branchId,
                orElse: () => const Branch(
                  id: -1,
                  name: '',
                  afipAvailable: false,
                  applyPerIibb: false,
                  applyPerVat: false,
                ),
              );
              if (branch.id == -1) return false;
              return (branch.priority ?? 0) >= maxMinPriority;
            });
            allowedForMethod.addAll(validBranches);
          } else {
            // Si la lista de sucursales está vacía pero tiene prioridad mínima configurada
            final matchingBranches = _allBranches
                .where((b) => (b.priority ?? 0) >= maxMinPriority)
                .map((b) => b.id);
            allowedForMethod.addAll(matchingBranches);
          }
        } else {
          // Si no hay configuración para este método de pago, permite todas las sucursales que cumplan con la prioridad mínima
          final matchingBranches = _allBranches
              .where((b) => (b.priority ?? 0) >= maxMinPriority)
              .map((b) => b.id);
          allowedForMethod.addAll(matchingBranches);
        }

        // Realizar la intersección de sucursales comunes
        if (commonBranchIds == null) {
          commonBranchIds = allowedForMethod;
        } else {
          commonBranchIds = commonBranchIds.intersection(allowedForMethod);
        }
      }

      // 3. Mapear los IDs comunes a objetos de tipo Branch
      if (commonBranchIds != null && commonBranchIds.isNotEmpty) {
        allowedBranches =
            _allBranches.where((b) => commonBranchIds!.contains(b.id)).toList();
      }

      // 4. Determinar la sucursal activa
      if (allowedBranches.isEmpty) {
        // Si no hay intersección o no hay coincidencia, retrocedemos al default del PDV
        final defaultBranch = _allBranches.firstWhere(
          (b) => b.id == _pdvConfig?.branchId,
          orElse: () => const Branch(
              id: -1,
              name: '',
              afipAvailable: false,
              applyPerIibb: false,
              applyPerVat: false),
        );
        if (defaultBranch.id != -1) {
          allowedBranches = [defaultBranch];
        }
        activeBranchId = _pdvConfig?.branchId;
      } else {
        // Si la sucursal seleccionada anteriormente sigue siendo válida dentro del nuevo conjunto, la conservamos
        final currentActiveInAllowed =
            allowedBranches.any((b) => b.id == state.activeBranchId);
        if (!currentActiveInAllowed) {
          // De lo contrario, seleccionamos por defecto la de la configuración del PDV si está entre las permitidas
          final hasPdvBranch =
              allowedBranches.any((b) => b.id == _pdvConfig?.branchId);
          if (hasPdvBranch) {
            activeBranchId = _pdvConfig?.branchId;
          } else {
            // Sino, seleccionamos la que tenga mayor prioridad
            Branch? bestBranch;
            for (final branch in allowedBranches) {
              if (bestBranch == null ||
                  (branch.priority ?? 0) > (bestBranch.priority ?? 0)) {
                bestBranch = branch;
              }
            }
            activeBranchId = bestBranch?.id;
          }
        } else {
          activeBranchId = state.activeBranchId;
        }
      }
    }

    _emitActiveBranch(
      activeBranchId: activeBranchId,
      allowedBranches: allowedBranches,
    );
  }

  ConfirmReturn buildConfirmReturnEvent() {
    final cartState = cartBloc.state;
    final items =
        cartState is CartLoaded ? cartState.items : const <CartItem>[];
    final logItems =
        cartState is CartLoaded ? cartState.log : const <CartLogEntry>[];

    return ConfirmReturn(
      reasonId: state.selectedReturnReasonId ?? -1,
      items: items,
      logItems: logItems,
      branchId: state.activeBranchId,
    );
  }

  ConfirmStockDispose buildConfirmStockDisposeEvent() {
    final cartState = cartBloc.state;
    final items =
        cartState is CartLoaded ? cartState.items : const <CartItem>[];
    final logItems =
        cartState is CartLoaded ? cartState.log : const <CartLogEntry>[];
    final reasonId = state.selectedDisposeReasonId ?? -1;
    final matched =
        state.disposeReasons.where((r) => r.id == reasonId).toList();
    final reasonDescription =
        matched.isEmpty ? '' : matched.first.description;

    return ConfirmStockDispose(
      reasonId: reasonId,
      reasonDescription: reasonDescription,
      items: items,
      logItems: logItems,
    );
  }

  @override
  void emit(CheckoutConfirmationState state) {
    if (isClosed) return;
    super.emit(state);
  }

  @override
  Future<void> close() {
    _cartSubscription.cancel();
    _clientsSubscription.cancel();
    return super.close();
  }
}
