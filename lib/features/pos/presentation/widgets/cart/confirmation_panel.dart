import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/core/utils/extensions.dart';
import 'package:punto_venta_app/features/pos/data/datasources/printer_local_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/pdv_local_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/branch_local_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/vat_category_local_datasource.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_state.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/checkout/checkout_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/checkout/checkout_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/checkout/checkout_state.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/clients/clients_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/clients/clients_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/clients/clients_state.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/payment_methods/payment_methods_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/payment_methods/payment_methods_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/payment_methods/payment_methods_state.dart';
import 'package:punto_venta_app/features/pos/domain/entities/payment_method.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/printer/printer_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/printer/printer_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/printer/printer_state.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/common/error_dialog.dart';
import 'package:punto_venta_app/features/pos/presentation/utils/iibb_calculator.dart';
import 'package:punto_venta_app/features/pos/presentation/utils/vat_perception_calculator.dart';
import 'package:punto_venta_app/features/pos/presentation/utils/internal_tax_calculator.dart';
import 'package:punto_venta_app/injection_container.dart' as di;
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_state.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/fetch_return_reasons_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/entities/return_reason.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/confirmation/payment_method_details_controllers.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/confirmation/checkout_confirmation_view.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/confirmation/return_confirmation_view.dart';

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
  double _iibbAmount = 0.0;
  double _vatPerceptionAmount = 0.0;
  double _internalTaxAmount = 0.0;

  List<PaymentMethod> _selectedPayments = [];
  final List<TextEditingController> _amountControllers = [];
  final List<TextEditingController> _receivedControllers = [];
  final List<PaymentMethodDetailsControllers> _detailsControllers = [];
  final Set<int> _expandedPaymentDetails = {};

  List<ReturnReason> _returnReasons = [];
  int? _selectedReturnReasonId;
  bool _isLoadingReasons = false;

  @override
  void dispose() {
    for (final controller in _amountControllers) {
      controller.dispose();
    }
    for (final controller in _receivedControllers) {
      controller.dispose();
    }
    for (final controller in _detailsControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  double get _totalAllocated =>
      _selectedPayments.fold(0.0, (sum, pm) => sum + (pm.amount ?? 0.0));

  // Lógica de montos y controllers
  void _updateChangeAndAmounts(double totalAmount) {
    double totalReceived = 0.0;
    double totalChange = 0.0;
    double totalAllocated = 0.0;

    for (final pm in _selectedPayments) {
      final isCash = pm.description.toLowerCase().contains('efectivo') ||
          pm.shortDescription.toLowerCase().contains('efectivo');
      final amount = pm.amount ?? 0.0;
      totalAllocated += amount;

      if (isCash) {
        final rec = pm.receivedAmount ?? amount;
        totalReceived += rec;
        if (rec > amount) {
          totalChange += (rec - amount);
        }
      } else {
        totalReceived += amount;
      }
    }

    setState(() {
      _receivedAmount = totalReceived;
      _change = totalChange;
    });
  }

  void _syncControllers() {
    while (_amountControllers.length > _selectedPayments.length) {
      _amountControllers.last.dispose();
      _amountControllers.removeLast();
    }
    while (_receivedControllers.length > _selectedPayments.length) {
      _receivedControllers.last.dispose();
      _receivedControllers.removeLast();
    }
    while (_detailsControllers.length > _selectedPayments.length) {
      _detailsControllers.last.dispose();
      _detailsControllers.removeLast();
    }

    for (int i = 0; i < _selectedPayments.length; i++) {
      final pm = _selectedPayments[i];
      final amountStr = pm.amount != null ? pm.amount!.toStringAsFixed(2) : '';
      final receivedStr = pm.receivedAmount != null
          ? pm.receivedAmount!.toStringAsFixed(2)
          : '';
      final details = pm.details;

      if (i >= _amountControllers.length) {
        _amountControllers.add(TextEditingController(text: amountStr));
      }

      if (i >= _receivedControllers.length) {
        _receivedControllers.add(TextEditingController(text: receivedStr));
      }

      if (i >= _detailsControllers.length) {
        final ctrl = PaymentMethodDetailsControllers();
        ctrl.accountOwner.text = details?.accountOwner ?? '';
        ctrl.bankId.text = details?.bankId ?? '';
        ctrl.checkNumber.text = details?.checkNumber ?? '';
        ctrl.transferId.text = details?.transferId ?? '';
        ctrl.verificationId.text = details?.verificationId ?? '';
        _detailsControllers.add(ctrl);
      } else {
        final ctrl = _detailsControllers[i];
        if (ctrl.accountOwner.text != (details?.accountOwner ?? '')) {
          ctrl.accountOwner.text = details?.accountOwner ?? '';
        }
        if (ctrl.bankId.text != (details?.bankId ?? '')) {
          ctrl.bankId.text = details?.bankId ?? '';
        }
        if (ctrl.checkNumber.text != (details?.checkNumber ?? '')) {
          ctrl.checkNumber.text = details?.checkNumber ?? '';
        }
        if (ctrl.transferId.text != (details?.transferId ?? '')) {
          ctrl.transferId.text = details?.transferId ?? '';
        }
        if (ctrl.verificationId.text != (details?.verificationId ?? '')) {
          ctrl.verificationId.text = details?.verificationId ?? '';
        }
      }
    }
  }

  // Builders de filas de pago (pasados como callbacks al CheckoutView)

  Widget _buildPaymentRow(
      int index, double totalAmount, List<PaymentMethod> allAvailableMethods) {
    _syncControllers();
    final pm = _selectedPayments[index];
    final isCash = pm.description.toLowerCase().contains('efectivo') ||
        pm.shortDescription.toLowerCase().contains('efectivo');

    return Card(
      key: ValueKey(pm.id),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getPaymentMethodIcon(pm.description, pm.shortDescription),
                    color: AppColors.success),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pm.description,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        pm.shortDescription,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (_selectedPayments.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete, color: AppColors.error),
                    onPressed: () {
                      setState(() {
                        _selectedPayments.removeAt(index);
                        if (index < _amountControllers.length) {
                          _amountControllers[index].dispose();
                          _amountControllers.removeAt(index);
                        }
                        if (index < _receivedControllers.length) {
                          _receivedControllers[index].dispose();
                          _receivedControllers.removeAt(index);
                        }
                        if (_selectedPayments.length == 1) {
                          final remaining = _selectedPayments[0];
                          _selectedPayments[0] =
                              remaining.copyWith(amount: totalAmount);
                          if (_amountControllers.isNotEmpty) {
                            _amountControllers[0].text =
                                totalAmount.toStringAsFixed(2);
                          }
                          context
                              .read<PaymentMethodsBloc>()
                              .add(SelectPaymentMethodEvent(remaining));
                        }
                        _updateChangeAndAmounts(totalAmount);
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _amountControllers[index],
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Monto a pagar',
                      prefixText: '\$ ',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (val) {
                      final double? parsed = double.tryParse(val);
                      setState(() {
                        _selectedPayments[index] = _selectedPayments[index]
                            .copyWith(amount: parsed ?? 0.0);
                        _updateChangeAndAmounts(totalAmount);
                      });
                    },
                  ),
                ),
                if (isCash) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _receivedControllers[index],
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Paga con (Recibido)',
                        prefixText: '\$ ',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (val) {
                        final double? parsed = double.tryParse(val);
                        setState(() {
                          _selectedPayments[index] = _selectedPayments[index]
                              .copyWith(receivedAmount: parsed);
                          _updateChangeAndAmounts(totalAmount);
                        });
                      },
                    ),
                  ),
                ],
              ],
            ),
            _buildDetailsForm(index, pm),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ValueChanged<String> onChanged,
  }) {
    return TextFormField(
      controller: controller,
      maxLength: 20,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        isDense: true,
      ),
      style: const TextStyle(fontSize: 13),
      onChanged: onChanged,
    );
  }

  void _updatePaymentDetails(int index,
      PaymentMethodDetails Function(PaymentMethodDetails d) updateFn) {
    setState(() {
      final currentDetails =
          _selectedPayments[index].details ?? const PaymentMethodDetails();
      final updatedDetails = updateFn(currentDetails);
      _selectedPayments[index] =
          _selectedPayments[index].copyWith(details: updatedDetails);
    });
  }

  Widget _buildDetailsForm(int index, PaymentMethod pm) {
    final desc = pm.description.toLowerCase();
    final shortDesc = pm.shortDescription.toLowerCase();

    // saber los id para saber que tipo es.

    final isCash = desc.contains('efectivo') || shortDesc.contains('efectivo');
    if (isCash) return const SizedBox.shrink();

    final isTransfer = desc.contains('transferencia') ||
        shortDesc.contains('transferencia') ||
        desc.contains('banco') ||
        shortDesc.contains('banco');
    final isCard = desc.contains('tarjeta') ||
        shortDesc.contains('tarjeta') ||
        desc.contains('debito') ||
        shortDesc.contains('debito') ||
        desc.contains('credito') ||
        shortDesc.contains('credito') ||
        desc.contains('posnet') ||
        shortDesc.contains('posnet');
    final isQR = desc.contains('qr') ||
        shortDesc.contains('qr') ||
        desc.contains('mercado') ||
        shortDesc.contains('mercado');
    final isCheck = desc.contains('cheque') || shortDesc.contains('cheque');

    _syncControllers();
    final controllers = _detailsControllers[index];
    final isExpanded = _expandedPaymentDetails.contains(pm.id);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedPaymentDetails.remove(pm.id);
                } else {
                  _expandedPaymentDetails.add(pm.id);
                }
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.assignment_outlined,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Datos adicionales del pago',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 18,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.only(
                  left: 12, right: 12, bottom: 12, top: 4),
              child: Column(
                spacing: 8,
                children: [
                  if (isCheck)
                    _buildDetailsTextField(
                      controller: controllers.checkNumber,
                      label: 'Número de cheque',
                      icon: Icons.pin_outlined,
                      onChanged: (val) {
                        _updatePaymentDetails(
                            index, (d) => d.copyWith(checkNumber: val));
                      },
                    ),
                  if (isTransfer || isQR)
                    _buildDetailsTextField(
                      controller: controllers.transferId,
                      label: 'ID de Transferencia/Operación',
                      icon: Icons.receipt_long_outlined,
                      onChanged: (val) {
                        _updatePaymentDetails(
                            index, (d) => d.copyWith(transferId: val));
                      },
                    ),
                  if (isCard || isQR)
                    _buildDetailsTextField(
                      controller: controllers.verificationId,
                      label: isCard
                          ? 'Nro. de Lote/Cupón (Verificación)'
                          : 'ID de Verificación',
                      icon: Icons.verified_outlined,
                      onChanged: (val) {
                        _updatePaymentDetails(
                            index, (d) => d.copyWith(verificationId: val));
                      },
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  IconData _getPaymentMethodIcon(String description, String shortDescription) {
    final desc = description.toLowerCase();
    final shortDesc = shortDescription.toLowerCase();
    if (desc.contains('efectivo') || shortDesc.contains('efectivo')) {
      return Icons.attach_money;
    }
    if (desc.contains('tarjeta') ||
        shortDesc.contains('tarjeta') ||
        desc.contains('debito') ||
        shortDesc.contains('debito') ||
        desc.contains('credito') ||
        shortDesc.contains('credito') ||
        desc.contains('posnet') ||
        shortDesc.contains('posnet')) {
      return Icons.credit_card;
    }
    if (desc.contains('transferencia') ||
        shortDesc.contains('transferencia') ||
        desc.contains('banco') ||
        shortDesc.contains('banco')) {
      return Icons.account_balance;
    }
    if (desc.contains('qr') ||
        shortDesc.contains('qr') ||
        desc.contains('mercado') ||
        shortDesc.contains('mercado')) {
      return Icons.qr_code;
    }
    return Icons.payment;
  }

  @override
  void initState() {
    super.initState();
    _initializeSelectedPayments();
    _calculateTaxesForUI();
    _loadReturnReasons();
  }

  void _initializeSelectedPayments() {
    if (_selectedPayments.isNotEmpty) return;
    final pmState = context.read<PaymentMethodsBloc>().state;
    if (pmState is PaymentMethodsLoaded &&
        pmState.selectedPaymentMethod != null) {
      _selectedPayments = [pmState.selectedPaymentMethod!];
    }
  }

  Future<void> _loadReturnReasons() async {
    setState(() {
      _isLoadingReasons = true;
    });
    try {
      final fetchReturnReasons = di.sl<FetchReturnReasonsUsecase>();
      final reasons = await fetchReturnReasons();
      setState(() {
        _returnReasons = reasons;
        if (reasons.isNotEmpty) {
          _selectedReturnReasonId = reasons.first.id;
        }
      });
    } catch (e) {
      print('⚠️ Error al cargar motivos de devolución: $e');
    } finally {
      setState(() {
        _isLoadingReasons = false;
      });
    }
  }

  void _confirmReturn(BuildContext context, CartLoaded cartState) {
    if (_selectedReturnReasonId == null) return;

    context.read<CheckoutBloc>().add(
          ConfirmReturn(
            reasonId: _selectedReturnReasonId!,
            items: cartState.items,
            logItems: cartState.log,
          ),
        );
  }

  //  calcular impuestos para mostrar en el UI (IIBB, percepción de IVA e impuesto interno)
  Future<void> _calculateTaxesForUI() async {
    final cartState = context.read<CartBloc>().state;
    if (cartState is! CartLoaded) {
      setState(() {
        _iibbAmount = 0.0;
        _vatPerceptionAmount = 0.0;
        _internalTaxAmount = 0.0;
      });
      return;
    }

    final cartLoaded = cartState;
    final internalTaxResult = InternalTaxCalculator.calculateInternalTax(
      items: cartLoaded.items,
    );
    final double computedInternalTax = internalTaxResult['total'] ?? 0.0;

    try {
      final clientsState = context.read<ClientsBloc>().state;
      final selectedClient =
          clientsState is ClientsLoaded ? clientsState.selectedClient : null;

      if (selectedClient == null) {
        setState(() {
          _iibbAmount = 0.0;
          _vatPerceptionAmount = 0.0;
          _internalTaxAmount = computedInternalTax;

          if (_selectedPayments.length == 1) {
            final total =
                cartLoaded.subtotal + cartLoaded.totalIva + computedInternalTax;
            _selectedPayments[0] = _selectedPayments[0].copyWith(amount: total);
            _syncControllers();
            if (_amountControllers.isNotEmpty) {
              _amountControllers[0].text = total.toStringAsFixed(2);
            }
          }
        });
        return;
      }

      // Obtener configuración del PDV (branch)
      final pdvConfig = await di.sl<PdvLocalDataSource>().getPdvConfig();
      final branchId = pdvConfig?.branchId;

      if (branchId == null) {
        setState(() {
          _iibbAmount = 0.0;
          _vatPerceptionAmount = 0.0;
          _internalTaxAmount = computedInternalTax;

          if (_selectedPayments.length == 1) {
            final total =
                cartLoaded.subtotal + cartLoaded.totalIva + computedInternalTax;
            _selectedPayments[0] = _selectedPayments[0].copyWith(amount: total);
            _syncControllers();
            if (_amountControllers.isNotEmpty) {
              _amountControllers[0].text = total.toStringAsFixed(2);
            }
          }
        });
        return;
      }

      // Obtener branch
      final branch =
          await di.sl<BranchLocalDataSource>().getBranchById(branchId);

      // Obtener VAT category
      final vatCategoryId = selectedClient.vatCategoryId;
      final vatCategoryDataSource = di.sl<VatCategoryLocalDataSource>();
      final allVatCategories =
          await vatCategoryDataSource.getCachedVatCategories();
      final vatCategory =
          allVatCategories?.where((cat) => cat.id == vatCategoryId).firstOrNull;

      // Calcular IIBB
      final iibb = IibbCalculator.calculateIibb(
        client: selectedClient,
        branch: branch,
        vatCategory: vatCategory,
        subtotal: cartLoaded.subtotal,
        totalWithVat: cartLoaded.subtotal + cartLoaded.totalIva,
      );

      // Calcular percepción de IVA
      final vatPerception = VatPerceptionCalculator.calculateVatPerception(
        cartItems: cartLoaded.items,
        branch: branch,
        vatCategory: vatCategory,
      );

      setState(() {
        _iibbAmount = iibb;
        _vatPerceptionAmount = vatPerception;
        _internalTaxAmount = computedInternalTax;

        if (_selectedPayments.length == 1) {
          final total = cartLoaded.subtotal +
              cartLoaded.totalIva +
              iibb +
              vatPerception +
              computedInternalTax;
          _selectedPayments[0] = _selectedPayments[0].copyWith(amount: total);
          _syncControllers();
          if (_amountControllers.isNotEmpty) {
            _amountControllers[0].text = total.toStringAsFixed(2);
          }
        }
      });
    } catch (e, stackTrace) {
      debugPrint('⚠️ Error calculating taxes for UI: $e\n$stackTrace');
      setState(() {
        _iibbAmount = 0.0;
        _vatPerceptionAmount = 0.0;
        _internalTaxAmount = computedInternalTax;

        if (_selectedPayments.length == 1) {
          final total =
              cartLoaded.subtotal + cartLoaded.totalIva + computedInternalTax;
          _selectedPayments[0] = _selectedPayments[0].copyWith(amount: total);
          _syncControllers();
          if (_amountControllers.isNotEmpty) {
            _amountControllers[0].text = total.toStringAsFixed(2);
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ClientsBloc, ClientsState>(
          listener: (context, clientsState) {
            // Recalcular impuestos cuando cambia el cliente
            _calculateTaxesForUI();
          },
        ),
        BlocListener<CartBloc, CartState>(
          listener: (context, cartState) {
            // Recalcular impuestos cuando cambia el carrito
            _calculateTaxesForUI();
          },
        ),
        BlocListener<PaymentMethodsBloc, PaymentMethodsState>(
          listener: (context, pmState) {
            if (pmState is PaymentMethodsLoaded) {
              final selected = pmState.selectedPaymentMethod;
              if (selected != null) {
                final cartState = context.read<CartBloc>().state;
                if (cartState is CartLoaded) {
                  final total = cartState.subtotal +
                      cartState.totalIva +
                      _iibbAmount +
                      _vatPerceptionAmount +
                      _internalTaxAmount;
                  if (_selectedPayments.isEmpty) {
                    setState(() {
                      _selectedPayments = [selected.copyWith(amount: total)];
                      _syncControllers();
                      if (_amountControllers.isNotEmpty) {
                        _amountControllers[0].text = total.toStringAsFixed(2);
                      }
                    });
                  } else if (_selectedPayments.length == 1 &&
                      _selectedPayments[0].id != selected.id) {
                    setState(() {
                      _selectedPayments[0] = selected.copyWith(amount: total);
                      _syncControllers();
                      if (_amountControllers.isNotEmpty) {
                        _amountControllers[0].text = total.toStringAsFixed(2);
                      }
                    });
                  }
                }
              }
            }
          },
        ),
        BlocListener<CheckoutBloc, CheckoutState>(
          listener: (context, checkoutState) async {
            // Cuando la venta se procesa exitosamente, imprimir ticket y limpiar estado
            if (checkoutState is CheckoutSuccess) {
              final uiState = context.read<UiBloc>().state;
              final isReturnMode =
                  uiState is UiLoaded ? uiState.isReturnMode : false;

              if (!isReturnMode) {
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
                printerBloc.close();
              }

              // Limpiar el carrito y cerrar el panel de confirmación
              if (mounted) {
                setState(() {
                  _receivedAmount = null;
                  _change = null;
                  _selectedPayments.clear();
                  _expandedPaymentDetails.clear();
                });

                context.read<CartBloc>().add(ClearCart());
                context.read<CheckoutBloc>().add(const ResetCheckout());
                context.read<ClientsBloc>().add(ResetToDefaultClientEvent());
                if (isReturnMode) {
                  context.read<UiBloc>().add(ToggleReturnMode());
                }
                widget.onClose();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isReturnMode
                        ? 'Devolución procesada exitosamente'
                        : 'Venta procesada exitosamente'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            } else if (checkoutState is CheckoutError) {
              if (mounted) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext dialogContext) {
                    return ErrorDialog(
                      message: checkoutState.message,
                      onAccept: () {
                        context.read<CheckoutBloc>().add(const ResetCheckout());
                      },
                    );
                  },
                );
              }
            }
          },
        ),
      ],
      child: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          if (state is! CartLoaded) {
            return const SizedBox.shrink();
          }

          final uiState = context.watch<UiBloc>().state;
          final isReturnMode =
              uiState is UiLoaded ? uiState.isReturnMode : false;

          final totalAmount = state.subtotal +
              state.totalIva +
              _iibbAmount +
              _vatPerceptionAmount +
              _internalTaxAmount;

          return BlocBuilder<CheckoutBloc, CheckoutState>(
            builder: (context, checkoutState) {
              final isProcessing = checkoutState is CheckoutProcessing;

              return Column(
                children: [
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
                          icon: const Icon(Icons.arrow_back),
                          onPressed: isProcessing ? null : _handleClose,
                        ),
                        const SizedBox(width: AppDimensions.paddingS),
                        Expanded(
                          child: Text(
                            isReturnMode
                                ? 'Confirmar Devolución'
                                : 'Confirmar Pago',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppDimensions.paddingL),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Vista de devolución
                          if (isReturnMode)
                            ReturnConfirmationView(
                              totalAmount: totalAmount,
                              isLoadingReasons: _isLoadingReasons,
                              returnReasons: _returnReasons,
                              selectedReturnReasonId: _selectedReturnReasonId,
                              onReturnReasonChanged: (id) =>
                                  setState(() => _selectedReturnReasonId = id),
                            )
                          // Vista de cobro
                          else
                            CheckoutConfirmationView(
                              totalAmount: totalAmount,
                              selectedPayments: _selectedPayments,
                              totalAllocated: _totalAllocated,
                              change: _change,
                              iibbAmount: _iibbAmount,
                              vatPerceptionAmount: _vatPerceptionAmount,
                              internalTaxAmount: _internalTaxAmount,
                              cartSubtotal: state.subtotal,
                              cartTotalIva: state.totalIva,
                              buildPaymentRow: _buildPaymentRow,
                              buildDetailsForm: _buildDetailsForm,
                              getPaymentMethodIcon: _getPaymentMethodIcon,
                              onMethodAdded: (pm, defaultAmount) {
                                setState(() {
                                  _selectedPayments
                                      .add(pm.copyWith(amount: defaultAmount));
                                  _updateChangeAndAmounts(totalAmount);
                                });
                              },
                              onCashAmountChanged: (amount) {
                                setState(() {
                                  _receivedAmount = amount;
                                  if (_selectedPayments.isNotEmpty &&
                                      (_selectedPayments[0]
                                              .description
                                              .toLowerCase()
                                              .contains('efectivo') ||
                                          _selectedPayments[0]
                                              .shortDescription
                                              .toLowerCase()
                                              .contains('efectivo'))) {
                                    _selectedPayments[0] = _selectedPayments[0]
                                        .copyWith(receivedAmount: amount);
                                  }
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
                              padding:
                                  const EdgeInsets.all(AppDimensions.paddingM),
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
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
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
                              onPressed: isProcessing ||
                                      (!isReturnMode &&
                                          _selectedPayments.length > 1 &&
                                          double.parse(_totalAllocated
                                                  .toStringAsFixed(2)) !=
                                              double.parse(totalAmount
                                                  .toStringAsFixed(2))) ||
                                      (isReturnMode &&
                                          _selectedReturnReasonId == null)
                                  ? null
                                  : () {
                                      if (isReturnMode) {
                                        _confirmReturn(context, state);
                                      } else {
                                        _confirmSale(context, state);
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isReturnMode
                                    ? AppColors.warning
                                    : AppColors.success,
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
                              onPressed: isProcessing ? null : _handleClose,
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

  // Función para confirmar la venta
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
            // total y totalIva
            total: cartState.total,
            totalIva: cartState.totalIva,
            subtotal: cartState.subtotal,
            client: selectedClient,
            paymentMethod: _selectedPayments.isNotEmpty
                ? _selectedPayments.first
                : selectedPaymentMethod,
            paymentMethods:
                _selectedPayments.isNotEmpty ? _selectedPayments : null,
            receivedAmount: _receivedAmount,
            change: _change,
          ),
        );
  }

  // Función para manejar el cierre del panel
  void _handleClose() {
    setState(() {
      _receivedAmount = null;
      _change = null;
    });
    widget.onClose();
  }
}
