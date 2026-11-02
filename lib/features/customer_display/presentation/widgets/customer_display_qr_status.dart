import 'package:flutter/material.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/features/customer_display/domain/customer_display_snapshot.dart';

/// Vista de estado del cobro QR en cliente.
class CustomerDisplayQrStatus extends StatelessWidget {
  const CustomerDisplayQrStatus({
    super.key,
    required this.phase,
    required this.label,
    this.detail,
    this.totalLabel,
  });

  final CustomerDisplayQrPhase phase;
  final String label;
  final String? detail;
  final String? totalLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = _configFor(phase, label);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: config.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(config.icon, size: 72, color: config.color),
              ),
              const SizedBox(height: 20),
              Text(
                config.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: config.color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                config.subtitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              if (totalLabel != null) ...[
                const SizedBox(height: 12),
                Text(
                  totalLabel!,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
              if (detail != null && detail!.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  detail!,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static _StatusConfig _configFor(
    CustomerDisplayQrPhase phase,
    String label,
  ) {
    switch (phase) {
      case CustomerDisplayQrPhase.pending:
        return _StatusConfig(
          icon: Icons.schedule,
          color: Colors.orange,
          title: 'Confirmando pago',
          subtitle: 'Estamos verificando el cobro con $label',
        );
      case CustomerDisplayQrPhase.approved:
        return _StatusConfig(
          icon: Icons.check_circle_outline,
          color: AppColors.success,
          title: 'Pago aprobado',
          subtitle: 'El cobro con $label fue confirmado',
        );
      case CustomerDisplayQrPhase.rejected:
        return _StatusConfig(
          icon: Icons.cancel_outlined,
          color: AppColors.error,
          title: 'Pago rechazado',
          subtitle: 'No se pudo completar el cobro con $label',
        );
      case CustomerDisplayQrPhase.expired:
        return const _StatusConfig(
          icon: Icons.timer_off_outlined,
          color: Colors.orange,
          title: 'QR expirado',
          subtitle: 'El código venció. Se generará uno nuevo en caja',
        );
      case CustomerDisplayQrPhase.ready:
      case CustomerDisplayQrPhase.none:
        return const _StatusConfig(
          icon: Icons.qr_code_2,
          color: AppColors.primary,
          title: 'Pago QR',
          subtitle: 'Escaneá el código para pagar',
        );
    }
  }
}

class _StatusConfig {
  const _StatusConfig({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
}
