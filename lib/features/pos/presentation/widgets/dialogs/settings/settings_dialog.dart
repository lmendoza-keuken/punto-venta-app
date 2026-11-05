import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/dialogs/logout_dialog.dart';
import 'package:punto_venta_app/core/services/windows_touch_input_service.dart';
import 'package:punto_venta_app/core/widgets/responsive_dialog_width.dart';
import 'package:punto_venta_app/features/customer_display/domain/customer_display_prefs.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/product/product_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/product/product_state.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/dialogs/settings/customer_display_advertising_dialog.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/dialogs/settings/pdv_settings_dialog.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/dialogs/settings/printer_settings_dialog.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/dialogs/settings/price_list_selector_dialog.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/dialogs/settings/payment_methods_settings_dialog.dart';
import 'package:punto_venta_app/injection_container.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        final currentList = state is ProductLoaded ? state.currentPriceList : 1;

        return AlertDialog(
          title: const Text('Configuración de administrador'),
          content: SingleChildScrollView(
            child: ResponsiveDialogWidth(
              preferredWidth: 420,
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
                        navigatorContext,
                        currentList,
                      );
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
                  if (CustomerDisplayPrefs.advertisingEnabled) ...[
                    const SizedBox(height: 10),
                    ActionCard(
                      icon: Icons.campaign_outlined,
                      iconColor: Colors.teal,
                      backgroundColor: Colors.teal.withValues(alpha: 0.1),
                      title: 'Publicidad pantalla cliente',
                      subtitle: 'Carrusel de productos en oferta fuera del POS',
                      onTap: () {
                        final productBloc = context.read<ProductBloc>();
                        final navigator = Navigator.of(context);
                        navigator.pop();
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          showCustomerDisplayAdvertisingDialog(
                            navigator.context,
                            productBloc: productBloc,
                          );
                        });
                      },
                    ),
                  ],
                  if (!kIsWeb &&
                      Platform.isWindows &&
                      sl.isRegistered<WindowsTouchInputService>()) ...[
                    const SizedBox(height: 10),
                    const _WindowsOnscreenKeyboardTile(),
                  ],
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

/// Preferencia para forzar el botón de teclado si no se detecta touch.
class _WindowsOnscreenKeyboardTile extends StatelessWidget {
  const _WindowsOnscreenKeyboardTile();

  @override
  Widget build(BuildContext context) {
    final service = sl<WindowsTouchInputService>();
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        final detected = service.isPrimaryDisplayTouch;
        final forced = service.isKeyboardForced;
        final subtitle = detected
            ? 'Pantalla táctil detectada — el botón ya está disponible'
            : forced
                ? 'Forzado: se muestra el botón aunque no se detecte touch'
                : 'Si no se detecta touch, activá esta opción para mostrar el botón';

        return Material(
          color: Colors.teal.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          child: SwitchListTile(
            secondary: const CircleAvatar(
              backgroundColor: Colors.teal,
              child: Icon(Icons.keyboard_alt_outlined, color: Colors.white),
            ),
            title: const Text(
              'Teclado en pantalla',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(subtitle),
            value: detected || forced,
            onChanged: detected
                ? null
                : (value) => service.setKeyboardForced(value),
          ),
        );
      },
    );
  }
}
