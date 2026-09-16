import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/widgets/custom_button.dart';
import 'package:punto_venta_app/features/app_update/domain/entities/app_release.dart';
import 'package:punto_venta_app/features/app_update/presentation/cubit/app_update_cubit.dart';
import 'package:punto_venta_app/features/app_update/presentation/cubit/app_update_state.dart';
import 'package:punto_venta_app/injection_container.dart' as di;

Future<bool> showUpdateAvailableDialog({
  required BuildContext context,
  required AppRelease release,
  required String currentVersion,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: !release.mandatory,
    builder: (dialogContext) {
      return BlocProvider(
        create: (_) => di.sl<AppUpdateCubit>(),
        child: _UpdateAvailableDialog(
          release: release,
          currentVersion: currentVersion,
        ),
      );
    },
  );

  return result ?? false;
}

class _UpdateAvailableDialog extends StatelessWidget {
  final AppRelease release;
  final String currentVersion;

  const _UpdateAvailableDialog({
    required this.release,
    required this.currentVersion,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppUpdateCubit, AppUpdateState>(
      builder: (context, state) {
        final isBusy = state.status == AppUpdateStatus.downloading ||
            state.status == AppUpdateStatus.verifying ||
            state.status == AppUpdateStatus.launching;

        return PopScope(
          canPop: !release.mandatory && !isBusy,
          child: AlertDialog(
            title: Text(
              release.mandatory
                  ? 'Actualización obligatoria'
                  : 'Nueva versión disponible',
            ),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Versión instalada: $currentVersion\n'
                    'Nueva versión: ${release.version}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (release.releaseNotes != null &&
                      release.releaseNotes!.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      release.releaseNotes!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                  if (isBusy) ...[
                    const SizedBox(height: 20),
                    LinearProgressIndicator(
                      value: state.progress > 0 && state.progress < 1
                          ? state.progress
                          : null,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.status == AppUpdateStatus.launching
                          ? 'Iniciando instalador...'
                          : 'Descargando... ${(state.progress * 100).clamp(0, 100).toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  if (state.status == AppUpdateStatus.error &&
                      state.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      state.errorMessage!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.red.shade700,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              if (!release.mandatory && !isBusy)
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Más tarde'),
                ),
              CustomButton(
                text: state.status == AppUpdateStatus.error
                    ? 'Reintentar'
                    : 'Actualizar',
                width: 140,
                isLoading: isBusy,
                onPressed: isBusy
                    ? null
                    : () => context.read<AppUpdateCubit>().startUpdate(release),
              ),
            ],
          ),
        );
      },
    );
  }
}
