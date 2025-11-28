import 'package:flutter/material.dart';

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

  void _save() {
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Configuración'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Aquí van las opciones de configuración.'),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar')),
        ElevatedButton(onPressed: _save, child: const Text('Guardar')),
      ],
    );
  }
}
