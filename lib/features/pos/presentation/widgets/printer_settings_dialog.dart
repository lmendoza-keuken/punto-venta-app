import 'package:flutter/material.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/features/pos/domain/entities/printer_config.dart';
import 'package:punto_venta_app/features/pos/data/datasources/printer_local_datasource.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/printer/printer_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/printer/printer_event.dart';
import 'package:punto_venta_app/injection_container.dart' as di;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/features/pos/domain/entities/print_job.dart';

Future<void> showPrinterSettingsDialog(BuildContext context) async {
  final ds = di.sl<PrinterLocalDataSource>();
  final config = await ds.getPrinterConfig();

  final ipController = TextEditingController(text: config.ip);
  final portController = TextEditingController(text: config.port.toString());
  final timeoutController =
      TextEditingController(text: config.timeout.toString());

  if (!context.mounted) return;

  await showDialog(
    context: context,
    builder: (ctx) {
      final formKey = GlobalKey<FormState>();
      return AlertDialog(
        title: const Text('Configuración de Impresora'),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: ipController,
                  decoration:
                      const InputDecoration(labelText: 'IP de la impresora'),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Ingresa la IP' : null,
                ),
                const SizedBox(height: AppDimensions.paddingM),
                TextFormField(
                  controller: portController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Puerto'),
                  validator: (v) => (v == null || int.tryParse(v) == null)
                      ? 'Puerto inválido'
                      : null,
                ),
                const SizedBox(height: AppDimensions.paddingM),
                TextFormField(
                  controller: timeoutController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Timeout (ms)'),
                  validator: (v) => (v == null || int.tryParse(v) == null)
                      ? 'Timeout inválido'
                      : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('Cancelar'),
          ),

          TextButton.icon(
            icon: const Icon(Icons.print),
            label: const Text('Ticket de prueba'),
            onPressed: () async {
              final currentConfig = PrinterConfig(
                ip: ipController.text.trim().isNotEmpty
                    ? ipController.text.trim()
                    : config.ip,
                port: int.tryParse(portController.text.trim()) ?? config.port,
                timeout: int.tryParse(timeoutController.text.trim()) ??
                    config.timeout,
              );

              Navigator.of(ctx).pop();

              final testJob = PrintJob(
                items: [],
                logItems: [],
                total: 30.0,
                totalTax: 0.0,
                clientName: 'Cliente de prueba',
                paymentMethod: 'Efectivo',
                cashierName: 'Ticket Prueba',
                timestamp: DateTime.now(),
                ticketId: 'TEST-${DateTime.now().millisecondsSinceEpoch}',
              );

              try {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enviando ticket de prueba...')),
                );

                context.read<PrinterBloc>().add(
                      PrintTicket(
                        printJob: testJob,
                        config: currentConfig,
                      ),
                    );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error al enviar ticket: $e')),
                );
              }
            },
          ),

          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final newConfig = PrinterConfig(
                ip: ipController.text.trim(),
                port: int.parse(portController.text.trim()),
                timeout: int.parse(timeoutController.text.trim()),
              );
              await ds.savePrinterConfig(newConfig);
              if (!context.mounted) return;
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Configuración guardada')),
              );
            },
            child: const Text('Guardar'),
          ),
        ],
      );
    },
  );
}
