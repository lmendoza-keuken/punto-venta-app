import 'package:flutter/material.dart';
import 'package:punto_venta_app/core/utils/app_logger.dart';
import 'package:punto_venta_app/features/auth/data/datasources/auth_local_datasources.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/bootstrap_mercado_pago_credentials_usecase.dart';
import 'package:punto_venta_app/injection_container.dart' as di;

/// Precarga token/caja de Mercado Pago si la empresa los tiene.
/// Sin credenciales no muestra error: MP es opcional.
Future<void> bootstrapMercadoPagoForCashier(BuildContext context) async {
  try {
    final enterprise = await di.sl<AuthLocalDataSource>().getCachedEnterprise();
    final user = await di.sl<AuthLocalDataSource>().getCachedUser();
    if (enterprise == null || user == null) return;

    final userId = int.tryParse(user.id);
    if (userId == null) return;

    final bootstrap = di.sl<BootstrapMercadoPagoCredentialsUsecase>();
    final result = await bootstrap(
      enterpriseId: enterprise.id,
      userId: userId,
      createPosIfMissing: false,
    );

    if (!result.hasToken) return;

    if (!result.needsCreatePos) return;

    if (!context.mounted) return;
    final shouldCreate = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Caja Mercado Pago'),
        content: const Text(
          'No hay una caja asignada a este usuario.\n\n'
          '¿Desea crear una caja para este usuario?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Crear'),
          ),
        ],
      ),
    );

    if (shouldCreate != true) return;

    try {
      final created = await bootstrap(
        enterpriseId: enterprise.id,
        userId: userId,
        createPosIfMissing: true,
      );
      if (!context.mounted) return;
      if (created.externalPosId != null) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Caja creada'),
            content: Text(
              'Caja creada exitosamente.\n\nID: ${created.externalPosId}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creando caja Mercado Pago: $e'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  } catch (e, stackTrace) {
    // MP es opcional: sin credenciales / fallos de lectura no deben
    // mostrar banner de error al cajero en el login.
    AppLogger.error(
      'bootstrapMercadoPagoForCashier: omitido (credenciales ausentes o fallo)',
      e,
      stackTrace,
    );
  }
}
