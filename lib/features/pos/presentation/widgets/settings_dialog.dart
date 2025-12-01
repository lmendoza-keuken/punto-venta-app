import 'package:flutter/material.dart';
import 'package:punto_venta_app/core/dialogs/logout_dialog.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/printer_settings_dialog.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  @override
  void dispose() {
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Configuración de administrador'),
      content: SizedBox(
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
              icon: Icons.app_registration_sharp,
              iconColor: Colors.blueAccent,
              backgroundColor: Colors.blueAccent.withOpacity(0.1),
              title: 'Configurar Modo de la App',
              subtitle: 'Configurar Modo En linea / Modo Offline',
              onTap: () {
              
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar')),
      ],
    );
  }
}
