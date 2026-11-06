import 'package:flutter/material.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/core/widgets/responsive_dialog_width.dart';
import 'package:punto_venta_app/features/customer_display/domain/customer_display_service.dart';
import 'package:punto_venta_app/injection_container.dart' as di;

Future<void> showCashierSettingsDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const CashierSettingsDialog(),
  );
}

/// Configuración visible para cajeros (no admin).
class CashierSettingsDialog extends StatelessWidget {
  const CashierSettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Configuración'),
      content: const SingleChildScrollView(
        child: ResponsiveDialogWidth(
          preferredWidth: 420,
          child: CustomerDisplaySettingsTile(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}

/// Toggle por equipo. La preferencia queda en SharedPreferences local:
/// solo en esta PC vuelve a abrirse sola.
class CustomerDisplaySettingsTile extends StatefulWidget {
  const CustomerDisplaySettingsTile({super.key});

  @override
  State<CustomerDisplaySettingsTile> createState() =>
      _CustomerDisplaySettingsTileState();
}

class _CustomerDisplaySettingsTileState
    extends State<CustomerDisplaySettingsTile> {
  final CustomerDisplayService _service = di.sl<CustomerDisplayService>();
  bool? _available;
  bool _enabled = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (!_service.isPlatformSupported) return;
    _enabled = _service.isEnabled;
    _detect();
  }

  Future<void> _detect() async {
    final available = await _service.isAvailable();
    if (!mounted) return;
    setState(() => _available = available);
  }

  Future<void> _onChanged(bool value) async {
    setState(() => _busy = true);
    try {
      await _service.setEnabled(value);
      if (!mounted) return;
      setState(() => _enabled = _service.isEnabled);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cambiar la pantalla cliente: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_service.isPlatformSupported) {
      return Text(
        'La pantalla cliente no está disponible en esta plataforma.',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
      );
    }

    // Solo se muestra el toggle si hay un 2º monitor usable.
    if (_available == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_available != true) {
      return Text(
        'Este equipo no tiene un segundo monitor disponible.',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
      );
    }

    final subtitle = _enabled
        ? 'Activada en este equipo. Se abre sola al iniciar.'
        : 'Segundo monitor detectado. Al activarla se abre y este equipo la recuerda.';

    return Container(
      padding: const EdgeInsets.only(left: 8, right: 4),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.teal.withValues(alpha: 0.3),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusM),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.teal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.borderRadiusM),
            ),
            child: const Icon(
              Icons.desktop_windows_outlined,
              color: Colors.teal,
              size: 24,
            ),
          ),
          const SizedBox(width: AppDimensions.paddingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pantalla cliente',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingXS),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Switch(value: _enabled, onChanged: _busy ? null : _onChanged),
        ],
      ),
    );
  }
}
