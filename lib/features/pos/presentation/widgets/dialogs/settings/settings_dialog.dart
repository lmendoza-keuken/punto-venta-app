import 'package:flutter/material.dart';
import 'package:punto_venta_app/core/dialogs/logout_dialog.dart';
import 'package:punto_venta_app/features/pos/data/datasources/price_list_local_datasource.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/dialogs/settings/pdv_settings_dialog.dart';
import 'package:punto_venta_app/injection_container.dart' as di;
import 'package:punto_venta_app/features/pos/presentation/widgets/dialogs/settings/printer_settings_dialog.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/dialogs/settings/price_list_selector_dialog.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/dialogs/settings/ticket_settings_dialog.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/dialogs/settings/app_mode_settings_dialog.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  final priceListDataSource = di.sl<PriceListLocalDataSource>();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: priceListDataSource.getCurrentPriceList(),
      builder: (context, snapshot) {
        final currentList = snapshot.data ?? 1;

        return AlertDialog(
          title: const Text('Configuración de administrador'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 420,
              child: Column(
                spacing: 10,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ActionCard(
                    icon: Icons.print,
                    iconColor: Colors.orange,
                    backgroundColor: Colors.orange.withOpacity(0.1),
                    title: 'Configurar impresoras',
                    subtitle: 'Configurar Ip de impresoras de tickets',
                    onTap: () {
                      final navigatorContext = Navigator.of(context).context;
                      Navigator.of(context).pop();
                      showPrinterSettingsDialog(navigatorContext);
                    },
                  ),
                  ActionCard(
                    icon: Icons.attach_money,
                    iconColor: Colors.green,
                    backgroundColor: Colors.green.withOpacity(0.1),
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
                  // ActionCard(
                  //   icon: Icons.receipt_long,
                  //   iconColor: Colors.purple,
                  //   backgroundColor: Colors.purple.withOpacity(0.1),
                  //   title: 'Configuración de Tickets',
                  //   subtitle:
                  //       'Configurar visualización de subtotal, IVA y precios',
                  //   onTap: () {
                  //     final navigatorContext = Navigator.of(context).context;
                  //     Navigator.of(context).pop();
                  //     showTicketSettingsDialog(navigatorContext);
                  //   },
                  // ),
                  ActionCard(
                    icon: Icons.point_of_sale,
                    iconColor: Colors.teal,
                    backgroundColor: Colors.teal.withOpacity(0.1),
                    title: 'Configurar PDV',
                    subtitle: 'Configurar datos del punto de venta',
                    onTap: () {
                      final navigatorContext = Navigator.of(context).context;
                      Navigator.of(context).pop();
                      showPdvSettingsDialog(navigatorContext, true);
                    },
                  ),
                  // ActionCard(
                  //   icon: Icons.app_registration_sharp,
                  //   iconColor: Colors.blueAccent,
                  //   backgroundColor: Colors.blueAccent.withOpacity(0.1),
                  //   title: 'Configurar Modo de la App',
                  //   subtitle: 'Configurar Modo En linea / Modo Offline',
                  //   onTap: () {
                  //     final navigatorContext = Navigator.of(context).context;
                  //     Navigator.of(context).pop();
                  //     showAppModeSettingsDialog(navigatorContext);
                  //   },
                  // ),
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
