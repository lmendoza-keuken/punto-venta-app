import 'package:flutter/material.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/features/pos/domain/entities/printer_config.dart';
import 'package:punto_venta_app/features/pos/data/datasources/printer_local_datasource.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/printer/printer_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/printer/printer_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/printer/printer_state.dart';
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
          final hasError = printerState is PrinterError;
          
          return AlertDialog(
            title: const Text('Configuración de Impresora'),
            content: Form(
              key: formKey,
              child: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Banner de información
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, size: 20, color: Colors.blue),
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
                    
                    // Banner de estado (si está imprimiendo)
                    if (isLoading)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: AppDimensions.paddingM),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: const Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Conectando con la impresora...',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Banner de error (si hay error)
                    if (hasError)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: AppDimensions.paddingM),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.error_outline, size: 20, color: Colors.red.shade700),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Error de conexión',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              (printerState as PrinterError).message,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '• Verifica que la impresora esté encendida\n'
                              '• Confirma que la IP sea correcta\n'
                              '• Asegúrate de estar en la misma red',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.red.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    
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
                        if (v == null || v.isEmpty) return 'Ingresa la IP';
                        final ipRegex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
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
                        helperText: 'Tiempo de espera para la conexión',
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Ingresa el timeout';
                        final timeout = int.tryParse(v);
                        if (timeout == null || timeout < 1000) {
                          return 'Timeout debe ser mayor a 1000ms';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
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
                        if (!formKey.currentState!.validate()) return;

                        final currentConfig = PrinterConfig(
                          ip: ipController.text.trim(),
                          port: int.tryParse(portController.text.trim()) ?? config.port,
                          timeout: int.tryParse(timeoutController.text.trim()) ??
                              config.timeout,
                        );

                        final testJob = PrintJob(
                          items: [],
                          logItems: [],
                          total: 0.0,
                          totalTax: 0.0,
                          clientName: 'Cliente de prueba',
                          paymentMethod: 'Efectivo',
                          cashierName: 'Ticket Prueba',
                          timestamp: DateTime.now(),
                          ticketId: 'TEST-${DateTime.now().millisecondsSinceEpoch}',
                          showSubtotalAndTax: true,
                          showPricesWithTax: false,
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
                        if (!formKey.currentState!.validate()) return;
                        
                        final newConfig = PrinterConfig(
                          ip: ipController.text.trim(),
                          port: int.parse(portController.text.trim()),
                          timeout: int.parse(timeoutController.text.trim()),
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