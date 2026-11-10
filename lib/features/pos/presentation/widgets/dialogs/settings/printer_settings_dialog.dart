import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/features/pos/data/datasources/printer_local_datasource.dart';
import 'package:punto_venta_app/features/pos/data/datasources/pta_thermal_printer.dart';
import 'package:punto_venta_app/features/pos/domain/entities/payment_method.dart';
import 'package:punto_venta_app/features/pos/domain/entities/print_job.dart';
import 'package:punto_venta_app/features/pos/domain/entities/printer_config.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/printer/printer_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/printer/printer_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/printer/printer_state.dart';
import 'package:punto_venta_app/injection_container.dart' as di;

Future<void> showPrinterSettingsDialog(BuildContext context) async {
  final ds = di.sl<PrinterLocalDataSource>();
  final config = await ds.getPrinterConfig();

  final ipController = TextEditingController(text: config.ip);
  final portController = TextEditingController(text: config.port.toString());
  final timeoutController =
      TextEditingController(text: config.timeout.toString());

  final isAndroid =
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  final builtinAvailable =
      isAndroid ? await PtaThermalPrinter.isAvailable() : false;
  final builtinInfo =
      builtinAvailable ? await PtaThermalPrinter.getInfo() : null;

  if (!context.mounted) return;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      final formKey = GlobalKey<FormState>();

      var selectedLabelType = config.labelType;
      var outputMode = config.outputMode;
      if (!builtinAvailable && outputMode == PrinterOutputMode.builtin) {
        outputMode = PrinterOutputMode.network;
      }

      return BlocConsumer<PrinterBloc, PrinterState>(
        listener: (context, state) {
          if (state is PrinterSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(state.message),
                  ],
                ),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, printerState) {
          final isLoading = printerState is PrinterPrinting;

          return AlertDialog(
            title: const Text('Configuración de Impresora'),
            content: StatefulBuilder(
              builder: (context, setDialogState) {
                final useNetworkFields =
                    outputMode == PrinterOutputMode.network ||
                        (outputMode == PrinterOutputMode.auto &&
                            !builtinAvailable);

                return SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: SizedBox(
                      width: AppDimensions.dialogWidth(context, 420),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (builtinAvailable) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: Colors.green.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.print,
                                      size: 20, color: Colors.green.shade700),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Impresora integrada detectada'
                                      '${builtinInfo?.version != null ? ' (${builtinInfo!.version})' : ''}'
                                      '${builtinInfo?.backend != null ? ' · ${builtinInfo!.backend}' : ''}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.green.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppDimensions.paddingM),
                            const Text(
                              'Salida de impresión',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SegmentedButton<PrinterOutputMode>(
                              style: ButtonStyle(
                                backgroundColor:
                                    WidgetStateProperty.resolveWith((states) {
                                  if (states.contains(WidgetState.selected)) {
                                    return AppColors.primary;
                                  }
                                  return null;
                                }),
                                foregroundColor:
                                    WidgetStateProperty.resolveWith((states) {
                                  if (states.contains(WidgetState.selected)) {
                                    return Colors.white;
                                  }
                                  return AppColors.primary;
                                }),
                                iconColor:
                                    WidgetStateProperty.resolveWith((states) {
                                  if (states.contains(WidgetState.selected)) {
                                    return Colors.white;
                                  }
                                  return AppColors.primary;
                                }),
                              ),
                              segments: const [
                                ButtonSegment(
                                  value: PrinterOutputMode.auto,
                                  label: Text('Auto'),
                                  icon: Icon(Icons.auto_awesome, size: 16),
                                ),
                                ButtonSegment(
                                  value: PrinterOutputMode.builtin,
                                  label: Text('Integrada'),
                                  icon: Icon(Icons.print, size: 16),
                                ),
                                ButtonSegment(
                                  value: PrinterOutputMode.network,
                                  label: Text('Por IP'),
                                  icon: Icon(Icons.router, size: 16),
                                ),
                              ],
                              selected: {outputMode},
                              onSelectionChanged: isLoading
                                  ? null
                                  : (next) {
                                      setDialogState(() {
                                        outputMode = next.first;
                                      });
                                    },
                            ),
                            const SizedBox(height: 6),
                            Text(
                              outputMode == PrinterOutputMode.auto
                                  ? 'Auto usa la integrada (papel ~58 mm) si está disponible; si no, la IP.'
                                  : outputMode == PrinterOutputMode.builtin
                                      ? 'Térmica del equipo · papel 57±0,5 mm × Ø50 mm (~58 mm).'
                                      : 'Se imprimirá por red ESC/POS (IP).',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: AppDimensions.paddingM),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: Colors.blue.shade200),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.info_outline,
                                      size: 20, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Configura la IP de tu impresora térmica',
                                      style: TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppDimensions.paddingM),
                          ],

                          if (isLoading)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(
                                  bottom: AppDimensions.paddingM),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: Colors.orange.shade200),
                              ),
                              child: const Row(
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Imprimiendo...',
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          if (printerState is PrinterError)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(
                                  bottom: AppDimensions.paddingM),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: Colors.red.shade200),
                              ),
                              child: Text(
                                printerState.message,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ),

                          if (useNetworkFields) ...[
                            TextFormField(
                              controller: ipController,
                              enabled: !isLoading,
                              decoration: const InputDecoration(
                                labelText: 'IP de la impresora',
                                hintText: '192.168.1.100',
                                prefixIcon: Icon(Icons.router),
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) {
                                if (!useNetworkFields) return null;
                                if (v == null || v.isEmpty) {
                                  return 'Ingresa la IP';
                                }
                                final ipRegex =
                                    RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
                                if (!ipRegex.hasMatch(v)) return 'IP inválida';
                                return null;
                              },
                            ),
                            const SizedBox(height: AppDimensions.paddingM),
                            TextFormField(
                              controller: timeoutController,
                              enabled: !isLoading,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Timeout (ms)',
                                hintText: '5000',
                                prefixIcon: Icon(Icons.timer),
                                border: OutlineInputBorder(),
                                helperText:
                                    'Tiempo de espera para la conexión',
                              ),
                              validator: (v) {
                                if (!useNetworkFields) return null;
                                if (v == null || v.isEmpty) {
                                  return 'Ingresa el timeout';
                                }
                                final timeout = int.tryParse(v);
                                if (timeout == null || timeout < 1000) {
                                  return 'Timeout debe ser mayor a 1000ms';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppDimensions.paddingM),
                          ],

                          DropdownButtonFormField<int>(
                            value: selectedLabelType,
                            decoration: const InputDecoration(
                              labelText: 'Tamaño de etiqueta de Góndola',
                              prefixIcon: Icon(Icons.straighten),
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 0,
                                child: Text('70x38mm (Grande)'),
                              ),
                              DropdownMenuItem(
                                value: 1,
                                child: Text('55x30mm (Estándar)'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setDialogState(() {
                                  selectedLabelType = value;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar'),
              ),
              OutlinedButton.icon(
                icon: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.print_outlined),
                label: const Text('Ticket de prueba'),
                onPressed: isLoading
                    ? null
                    : () async {
                        final needsIp = outputMode == PrinterOutputMode.network ||
                            (outputMode == PrinterOutputMode.auto &&
                                !builtinAvailable);
                        if (needsIp &&
                            !(formKey.currentState?.validate() ?? false)) {
                          return;
                        }

                        final currentConfig = PrinterConfig(
                          ip: ipController.text.trim(),
                          port: int.tryParse(portController.text.trim()) ??
                              config.port,
                          timeout:
                              int.tryParse(timeoutController.text.trim()) ??
                                  config.timeout,
                          labelType: selectedLabelType,
                          outputMode: outputMode,
                        );

                        final testJob = PrintJob(
                          items: [],
                          logItems: [],
                          total: 0.0,
                          totalTax: 0.0,
                          clientName: 'Cliente de prueba',
                          paymentMethod: const PaymentMethod(
                            id: 1,
                            description: 'Efectivo',
                            shortDescription: 'Efectivo',
                            deleteAt: '',
                          ),
                          cashierName: 'Ticket Prueba',
                          timestamp: DateTime.now(),
                          ticketId:
                              'TEST-${DateTime.now().millisecondsSinceEpoch}',
                          showSubtotalAndTax: true,
                          showPricesWithTax: false,
                          branchNumber: 'Sucursal Prueba',
                        );

                        context.read<PrinterBloc>().add(
                              PrintTicket(
                                printJob: testJob,
                                config: currentConfig,
                              ),
                            );
                      },
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Guardar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: isLoading
                    ? null
                    : () async {
                        final needsIp = outputMode == PrinterOutputMode.network ||
                            (outputMode == PrinterOutputMode.auto &&
                                !builtinAvailable);
                        if (needsIp &&
                            !(formKey.currentState?.validate() ?? false)) {
                          return;
                        }

                        final newConfig = PrinterConfig(
                          ip: ipController.text.trim(),
                          port: int.tryParse(portController.text.trim()) ??
                              config.port,
                          timeout:
                              int.tryParse(timeoutController.text.trim()) ??
                                  config.timeout,
                          labelType: selectedLabelType,
                          outputMode: outputMode,
                        );

                        await ds.savePrinterConfig(newConfig);

                        if (!ctx.mounted) return;
                        Navigator.of(ctx).pop();

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.white),
                                SizedBox(width: 8),
                                Text('Configuración guardada correctamente'),
                              ],
                            ),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
              ),
            ],
          );
        },
      );
    },
  );
}
