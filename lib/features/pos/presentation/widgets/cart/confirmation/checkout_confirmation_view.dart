import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/core/utils/extensions.dart';
import 'package:punto_venta_app/features/pos/domain/entities/payment_method.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/payment_methods/payment_methods_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/payment_methods/payment_methods_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/payment_methods/payment_methods_state.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/cash_payment_widget.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/confirmation/add_payment_method_button.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/payment_method_dialogs.dart';

class CheckoutConfirmationView extends StatelessWidget {
  final double totalAmount;
  final List<PaymentMethod> selectedPayments;
  final double totalAllocated;
  final double? change;

  // Impuestos extra (IIBB, perc. IVA, imp. interno)
  final double iibbAmount;
  final double vatPerceptionAmount;
  final double internalTaxAmount;

  // Para el desglose de impuestos
  final double cartSubtotal;
  final double cartTotalIva;

  final Widget Function(
    int index,
    double totalAmount,
    List<PaymentMethod> allMethods,
  ) buildPaymentRow;

  // funcion que construye el formulario de detalles de cada metodo de pago
  final Widget Function(int index, PaymentMethod pm) buildDetailsForm;

  final IconData Function(String description, String shortDescription)
      getPaymentMethodIcon;

  /// Se llama cuando el usuario elige agregar un segundo método de pago.
  final void Function(PaymentMethod pm, double defaultAmount) onMethodAdded;

  /// Callbacks del widget de cobro en efectivo.
  final ValueChanged<double?> onCashAmountChanged;
  final ValueChanged<double?> onChangeCalculated;

  const CheckoutConfirmationView({
    super.key,
    required this.totalAmount,
    required this.selectedPayments,
    required this.totalAllocated,
    required this.change,
    required this.iibbAmount,
    required this.vatPerceptionAmount,
    required this.internalTaxAmount,
    required this.cartSubtotal,
    required this.cartTotalIva,
    required this.buildPaymentRow,
    required this.buildDetailsForm,
    required this.getPaymentMethodIcon,
    required this.onMethodAdded,
    required this.onCashAmountChanged,
    required this.onChangeCalculated,
  });

  // widget que construye los pagos multiples del param de selectedPayments
  Widget _buildMultiplePayments(
    BuildContext context,
    List<PaymentMethod> paymentMethods,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...List.generate(
          selectedPayments.length,
          (index) => buildPaymentRow(index, totalAmount, paymentMethods),
        ),
        const SizedBox(height: 12),
        // boton de agregar metodo de pago
        Align(
          alignment: Alignment.centerRight,
          child: AddPaymentMethodButton(
            onPressed: () => showAddPaymentMethodDialog(
              context: context,
              allMethods: paymentMethods,
              selectedPayments: selectedPayments,
              totalAmount: totalAmount,
              totalAllocated: totalAllocated,
              getPaymentMethodIcon: getPaymentMethodIcon,
              onMethodAdded: onMethodAdded,
            ),
          ),
        ),
        const SizedBox(height: 16),

        _allocationSummary(),
        if (double.parse(totalAllocated.toStringAsFixed(2)) !=
            double.parse(totalAmount.toStringAsFixed(2))) ...[
          const SizedBox(height: 12),
          _allocationWarning(),
        ],
      ],
    );
  }

  // widget de Build cuando es solo un metodo de pago, abre el dialogo para seleccionar y
  Widget _buildSinglePayment(
    BuildContext context,
    PaymentMethod? selected,
    List<PaymentMethod> paymentMethods,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => showPaymentMethodsSelectorDialog(
            context: context,
            paymentMethods: paymentMethods,
            selectedPaymentMethod: selected,
            getPaymentMethodIcon: getPaymentMethodIcon,
            onSelected: (pm) {
              context
                  .read<PaymentMethodsBloc>()
                  .add(SelectPaymentMethodEvent(pm));
            },
          ),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.success.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    getPaymentMethodIcon(
                      selected?.description ?? '',
                      selected?.shortDescription ?? '',
                    ),
                    color: AppColors.success,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppDimensions.paddingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selected?.description ?? 'Seleccionar método de pago',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (selected != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          selected.shortDescription,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),
          ),
        ),
        // si hay pagos seleccionados , se muestra el formulario de detalles
        if (selectedPayments.isNotEmpty) ...[
          buildDetailsForm(0, selectedPayments[0]),
          const SizedBox(height: 12),
        ],
        // boton de agregar otro metodo de pago
        Align(
          alignment: Alignment.centerRight,
          child: _addMethodButton(context, paymentMethods),
        ),
      ],
    );
  }

  // widget de boton de agregar otro metodo de pago
  Widget _addMethodButton(
    BuildContext context,
    List<PaymentMethod> paymentMethods,
  ) {
    return OutlinedButton.icon(
      onPressed: () => showAddPaymentMethodDialog(
        context: context,
        allMethods: paymentMethods,
        selectedPayments: selectedPayments,
        totalAmount: totalAmount,
        totalAllocated: totalAllocated,
        getPaymentMethodIcon: getPaymentMethodIcon,
        onMethodAdded: onMethodAdded,
      ),
      icon: const Icon(Icons.add),
      label: const Text('Agregar Otro Método'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // Widget que construye el resumen del pago
  Widget _allocationSummary() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Venta:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                totalAmount.formatToCurrency(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Asignado:'),
              Text(
                totalAllocated.formatToCurrency(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: double.parse(totalAllocated.toStringAsFixed(2)) ==
                          double.parse(totalAmount.toStringAsFixed(2))
                      ? AppColors.success
                      : AppColors.error,
                ),
              ),
            ],
          ),
          if (change != null && change! > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Vuelto / Cambio:',
                  style: TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  change!.formatToCurrency(),
                  style: const TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // widget de warning si falta asignar o hay excedente de dinero
  Widget _allocationWarning() {
    final isShort = totalAllocated < totalAmount;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning, color: AppColors.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isShort
                  ? 'Falta asignar: \$ ${(totalAmount - totalAllocated).toStringAsFixed(2)}'
                  : 'El monto asignado supera el total por \$ ${(totalAllocated - totalAmount).toStringAsFixed(2)}',
              style: const TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // widget que construye el desglose de impuestos
  Widget _taxBreakdown() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.info.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _taxRow('Subtotal:', '\$ ${cartSubtotal.toStringAsFixed(2)}',
                  isBold: false),
              const SizedBox(height: 8),
              _taxRow('IVA:', '\$ ${cartTotalIva.toStringAsFixed(2)}',
                  isBold: false),
              if (iibbAmount > 0) ...[
                const SizedBox(height: 8),
                _taxRow(
                  'Percep. IIBB:',
                  '\$ ${iibbAmount.toStringAsFixed(2)}',
                  color: AppColors.info,
                ),
              ],
              if (vatPerceptionAmount > 0) ...[
                const SizedBox(height: 8),
                _taxRow(
                  'Percep. IVA:',
                  '\$ ${vatPerceptionAmount.toStringAsFixed(2)}',
                  color: AppColors.info,
                ),
              ],
              if (internalTaxAmount > 0) ...[
                const SizedBox(height: 8),
                _taxRow(
                  'Imp. Interno:',
                  '\$ ${internalTaxAmount.toStringAsFixed(2)}',
                  color: AppColors.info,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // widget que hace el taxRow con un label y un valor
  Widget _taxRow(String label, String value,
      {Color? color, bool isBold = true}) {
    final style = TextStyle(
      fontSize: 14,
      fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
      color: color,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: TextStyle(fontSize: 14, color: color)),
      ],
    );
  }

  // BUILD principal
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Métodos de Pago',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),

        // Selector / filas de métodos de pago
        BlocBuilder<PaymentMethodsBloc, PaymentMethodsState>(
          builder: (context, pmState) {
            // estado de carga
            if (pmState is PaymentMethodsLoading) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              );
            }

            // estado de error
            if (pmState is PaymentMethodsError) {
              return Container(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        size: 20, color: AppColors.error),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Error al cargar métodos de pago: ${pmState.message}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              );
            }

            if (pmState is PaymentMethodsLoaded) {
              final paymentMethods = pmState.paymentMethods;
              final selected = pmState.selectedPaymentMethod;

              // si viene el array vacio.
              if (paymentMethods.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.warning.withOpacity(0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning, size: 20, color: AppColors.warning),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No hay métodos de pago disponibles',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                );
              }

              // si es mas de un metodo de pago, construye un build diferente.
              if (selectedPayments.length > 1) {
                return _buildMultiplePayments(context, paymentMethods);
              }
              // si es solo un metodo de pago, construye el build normal.
              return _buildSinglePayment(context, selected, paymentMethods);
            }

            return const SizedBox.shrink();
          },
        ),

        const SizedBox(height: 24),
        const Divider(height: 1),
        const SizedBox(height: 24),

        // Desglose de impuestos (solo si aplican percepciones) ( componetizar mandar a otro archivo)
        if (iibbAmount > 0 || vatPerceptionAmount > 0 || internalTaxAmount > 0)
          _taxBreakdown(),

        // Widget de efectivo (solo para un método de pago)
        if (selectedPayments.length <= 1)
          CashPaymentWidget(
            key: ValueKey(totalAmount),
            totalAmount: totalAmount,
            onAmountChanged: onCashAmountChanged,
            onChangeCalculated: onChangeCalculated,
          ),
      ],
    );
  }
}
