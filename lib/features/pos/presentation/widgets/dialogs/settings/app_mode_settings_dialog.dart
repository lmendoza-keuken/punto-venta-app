import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/pdv_config/pdv_config_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/pdv_config/pdv_config_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/pdv_config/pdv_config_state.dart';
import 'package:punto_venta_app/injection_container.dart' as di;

Future<void> showAppModeSettingsDialog(BuildContext context) async {
  return await showDialog(
    context: context,
    builder: (ctx) => BlocProvider(
      create: (_) => di.sl<PdvConfigBloc>()..add(FetchPdvConfigEvent()),
      child: const _AppModeSettingsDialogContent(),
    ),
  );
}

class _AppModeSettingsDialogContent extends StatefulWidget {
  const _AppModeSettingsDialogContent();

  @override
  State<_AppModeSettingsDialogContent> createState() =>
      _AppModeSettingsDialogContentState();
}

class _AppModeSettingsDialogContentState
    extends State<_AppModeSettingsDialogContent> {
  bool _offlineMode = false;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PdvConfigBloc, PdvConfigState>(
      listener: (context, state) {
        if (state is PdvConfigLoaded) {
          setState(() {
            _offlineMode = state.config.offlineMode ?? false;
          });
        } else if (state is OfflineModeUpdated) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(
                    'Modo ${state.offlineMode ? "offline" : "en línea"} activado correctamente',
                  ),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (state is PdvConfigError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text(state.message)),
                ],
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is PdvConfigLoading;

        return AlertDialog(
          title: const Text('Configurar Modo de la App'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selecciona el modo de la aplicación:',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),

                // Modo En Línea
                InkWell(
                  onTap: isLoading
                      ? null
                      : () {
                          setState(() {
                            _offlineMode = false;
                          });
                        },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: !_offlineMode
                            ? AppColors.primary
                            : Colors.grey.shade300,
                        width: !_offlineMode ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: !_offlineMode
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : Colors.transparent,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.cloud_queue,
                          color:
                              !_offlineMode ? AppColors.primary : Colors.grey,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Modo En Línea',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: !_offlineMode
                                      ? AppColors.primary
                                      : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'La aplicación estará conectada al servidor para sincronización en tiempo real.',
                                style:
                                    TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        Radio<bool>(
                          value: false,
                          groupValue: _offlineMode,
                          onChanged: isLoading
                              ? null
                              : (value) {
                                  setState(() {
                                    _offlineMode = value!;
                                  });
                                },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Modo Offline
                InkWell(
                  onTap: isLoading
                      ? null
                      : () {
                          setState(() {
                            _offlineMode = true;
                          });
                        },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _offlineMode
                            ? AppColors.primary
                            : Colors.grey.shade300,
                        width: _offlineMode ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: _offlineMode
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : Colors.transparent,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.cloud_off,
                          color: _offlineMode ? AppColors.primary : Colors.grey,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Modo Offline',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _offlineMode
                                      ? AppColors.primary
                                      : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'La aplicación trabajará sin conexión, guardando datos localmente.',
                                style:
                                    TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        Radio<bool>(
                          value: true,
                          groupValue: _offlineMode,
                          onChanged: isLoading
                              ? null
                              : (value) {
                                  setState(() {
                                    _offlineMode = value!;
                                  });
                                },
                        ),
                      ],
                    ),
                  ),
                ),

                if (isLoading) ...[
                  const SizedBox(height: 16),
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () {
                      context.read<PdvConfigBloc>().add(
                            UpdateOfflineModeEvent(_offlineMode),
                          );
                    },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }
}
