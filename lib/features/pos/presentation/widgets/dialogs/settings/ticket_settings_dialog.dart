import 'package:flutter/material.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/features/pos/domain/entities/ticket_config.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/get_ticket_config_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/update_ticket_config_usecase.dart';
import 'package:punto_venta_app/injection_container.dart' as di;

void showTicketSettingsDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const TicketSettingsDialog(),
  );
}

class TicketSettingsDialog extends StatefulWidget {
  const TicketSettingsDialog({super.key});

  @override
  State<TicketSettingsDialog> createState() => _TicketSettingsDialogState();
}

class _TicketSettingsDialogState extends State<TicketSettingsDialog> {
  final getTicketConfigUsecase = di.sl<GetTicketConfigUsecase>();
  final updateTicketConfigUsecase = di.sl<UpdateTicketConfigUsecase>();

  bool _isLoading = true;
  bool _isSaving = false;
  TicketConfig? _config;
  bool _showSubtotalAndTax = false;
  bool _showPricesWithTax = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      final config = await getTicketConfigUsecase();
      if (mounted) {
        setState(() {
          _config = config;
          _showSubtotalAndTax = config?.showSubtotalAndTax ?? false;
          _showPricesWithTax = config?.showPricesWithTax ?? true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar configuración: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _saveConfig() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final TicketConfig configToSave;

      if (_config == null) {
        configToSave = TicketConfig(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          showSubtotalAndTax: _showSubtotalAndTax,
          showPricesWithTax: _showPricesWithTax,
          lastUpdated: DateTime.now(),
        );
      } else {
        configToSave = _config!.copyWith(
          showSubtotalAndTax: _showSubtotalAndTax,
          showPricesWithTax: _showPricesWithTax,
          lastUpdated: DateTime.now(),
        );
      }

      await updateTicketConfigUsecase(configToSave);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuración actualizada correctamente'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar configuración: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Configuración de Tickets'),
      content: _isLoading
          ? const SizedBox(
              width: 300,
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            )
          : SizedBox(
              width: 450,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Mostrar Subtotal e IVA'),
                    subtitle: const Text(
                      'Muestra el desglose en los tickets. '
                      'Si está desactivado, no se mostrará sin importar el cliente.',
                    ),
                    value: _showSubtotalAndTax,
                    onChanged: (value) {
                      setState(() {
                        _showSubtotalAndTax = value;
                      });
                    },
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Mostrar Precios con IVA'),
                    subtitle: const Text(
                      'Muestra los precios de los productos con IVA incluido en los tickets.',
                    ),
                    value: _showPricesWithTax,
                    onChanged: (value) {
                      setState(() {
                        _showPricesWithTax = value;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'El formato del ticket se determina automáticamente '
                            'según la categoría IVA del cliente y la configuración de la sucursal.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isSaving || _isLoading ? null : _saveConfig,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }
}
