import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/dialogs/logout_dialog.dart';
import 'package:punto_venta_app/features/customer_display/domain/customer_display_service.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/product/product_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/product/product_state.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/dialogs/settings/pdv_settings_dialog.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/dialogs/settings/printer_settings_dialog.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/dialogs/settings/price_list_selector_dialog.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/dialogs/settings/payment_methods_settings_dialog.dart';
import 'package:punto_venta_app/injection_container.dart' as di;

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late bool _customerDisplayEnabled;
  late final CustomerDisplayService _customerDisplay;

  @override
  void initState() {
    super.initState();
    _customerDisplay = di.sl<CustomerDisplayService>();
    _customerDisplayEnabled = _customerDisplay.isEnabled;
  }

  Future<void> _toggleCustomerDisplay(bool enabled) async {
    setState(() => _customerDisplayEnabled = enabled);
    await _customerDisplay.setEnabled(enabled);
    if (enabled) {
      await _customerDisplay.start();
    } else {
      await _customerDisplay.stop();
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          enabled
              ? 'Pantalla cliente activada'
              : 'Pantalla cliente desactivada',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        final currentList = state is ProductLoaded ? state.currentPriceList : 1;

        return AlertDialog(
          title: const Text('Configuración de administrador'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ActionCard(
                    icon: Icons.print,
                    iconColor: Colors.teal,
                    backgroundColor: Colors.teal.withValues(alpha: 0.1),
                    title: 'Configurar impresoras',
                    subtitle: 'Configurar Ip de impresoras de tickets',
                    onTap: () {
                      final navigatorContext = Navigator.of(context).context;
                      Navigator.of(context).pop();
                      showPrinterSettingsDialog(navigatorContext);
                    },
                  ),
                  const SizedBox(height: 10),
                  ActionCard(
                    icon: Icons.attach_money,
                    iconColor: Colors.teal,
                    backgroundColor: Colors.teal.withValues(alpha: 0.1),
                    title: 'Lista de Precios',
                    subtitle:
                        'Cambiar lista de precios activa (Actual: Lista $currentList)',
                    onTap: () {
                      final navigatorContext = Navigator.of(context).context;
                      Navigator.of(context).pop();
                      showPriceListSelectorDialog(
                          navigatorContext, currentList);
                    },
                  ),
                  const SizedBox(height: 10),
                  ActionCard(
                    icon: Icons.point_of_sale,
                    iconColor: Colors.teal,
                    backgroundColor: Colors.teal.withValues(alpha: 0.1),
                    title: 'Configurar PDV',
                    subtitle: 'Configurar datos del punto de venta',
                    onTap: () {
                      final navigatorContext = Navigator.of(context).context;
                      Navigator.of(context).pop();
                      showPdvSettingsDialog(navigatorContext, true);
                    },
                  ),
                  const SizedBox(height: 10),
                  ActionCard(
                    icon: Icons.monetization_on_rounded,
                    iconColor: Colors.teal,
                    backgroundColor: Colors.teal.withValues(alpha: 0.1),
                    title: 'Configurar Metodos de Pago',
                    subtitle: 'Vincular metodos de pago con sucursales',
                    onTap: () {
                      final navigatorContext = Navigator.of(context).context;
                      Navigator.of(context).pop();
                      showPaymentMethodsSettingsDialog(navigatorContext);
                    },
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.teal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.tv, color: Colors.teal),
                    ),
                    title: const Text('Pantalla cliente'),
                    subtitle: const Text(
                      'Mostrar carrito y total en la segunda pantalla',
                    ),
                    value: _customerDisplayEnabled,
                    onChanged: _toggleCustomerDisplay,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }
}
