import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/features/pos/domain/entities/client.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/constants/app_dimensions.dart';
import '../../../bloc/clients/clients_bloc.dart';
import '../../../bloc/clients/clients_event.dart';
import '../../../bloc/clients/clients_state.dart';

class SelectClientDialog extends StatefulWidget {
  const SelectClientDialog({super.key});

  @override
  State<SelectClientDialog> createState() => _SelectClientDialogState();
}

class _SelectClientDialogState extends State<SelectClientDialog> {
  Client? _selected;

  @override
  void initState() {
    super.initState();
    context.read<ClientsBloc>().add(LoadClients());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.person_search, color: AppColors.primary),
          const SizedBox(width: AppDimensions.paddingS),
          Text('Seleccionar Cliente',
              style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
      content: SizedBox(
        width: 600,
        height: 540,
        child: Column(
          children: [
            // Cliente actualmente seleccionado
            BlocBuilder<ClientsBloc, ClientsState>(
              builder: (context, state) {
                final selectedClient =
                    state is ClientsLoaded ? state.selectedClient : null;

                return Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  margin: const EdgeInsets.only(bottom: AppDimensions.paddingM),
                  decoration: BoxDecoration(
                    color: selectedClient == null
                        ? AppColors.warning.withOpacity(0.1)
                        : AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selectedClient == null
                          ? AppColors.warning.withOpacity(0.3)
                          : AppColors.success.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selectedClient == null
                            ? Icons.person_off
                            : Icons.person,
                        color: selectedClient == null
                            ? AppColors.warning
                            : AppColors.success,
                        size: 32,
                      ),
                      const SizedBox(width: AppDimensions.paddingM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cliente Actual',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            if (selectedClient != null) ...[
                              Text(
                                selectedClient.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              if (selectedClient.document != null)
                                Text(
                                  selectedClient.document!,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                            ] else ...[
                              Row(
                                children: [
                                  Text(
                                    'Sin cliente seleccionado',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.warning,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'CONSUMIDOR FINAL',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (selectedClient != null)
                        IconButton(
                          icon: const Icon(Icons.clear, color: AppColors.error),
                          tooltip: 'Deseleccionar cliente',
                          onPressed: () {
                            context.read<ClientsBloc>().add(
                                  const SelectClientEvent(null),
                                );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Cliente deseleccionado - Consumidor Final'),
                                backgroundColor: AppColors.warning,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                );
              },
            ),
            const Divider(),
            const SizedBox(height: AppDimensions.paddingS),
            Text(
              'Lista de Clientes',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppDimensions.paddingS),
            Expanded(
              child: BlocBuilder<ClientsBloc, ClientsState>(
                builder: (context, state) {
                  if (state is ClientsLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is ClientsLoaded) {
                    final clients = state.clients;
                    if (clients.isEmpty) {
                      return const Center(
                          child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.person,
                              color: AppColors.addClientButton),
                          Text('No hay clientes guardados'),
                        ],
                      ));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(AppDimensions.paddingM),
                      itemCount: clients.length,
                      itemBuilder: (context, index) {
                        final c = clients[index];
                        final isSelected = _selected?.id == c.id;
                        return Card(
                          color: isSelected
                              ? AppColors.primary.withOpacity(0.08)
                              : null,
                          child: ListTile(
                            title: Text(c.name),
                            subtitle: Text(
                                '${c.document ?? ''}${c.phone != null ? ' • ${c.phone}' : ''}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: AppColors.error),
                                  onPressed: () => _confirmDelete(c),
                                ),
                              ],
                            ),
                            onTap: () {
                              setState(() => _selected = c);
                            },
                          ),
                        );
                      },
                    );
                  }
                  if (state is ClientsError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppColors.error,
                            size: 48,
                          ),
                          const SizedBox(height: AppDimensions.paddingM),
                          Text(
                            'Error al cargar clientes',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppDimensions.paddingS),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimensions.paddingL,
                            ),
                            child: Text(
                              state.message,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          const SizedBox(height: AppDimensions.paddingL),
                          ElevatedButton.icon(
                            onPressed: () {
                              context.read<ClientsBloc>().add(LoadClients());
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              child: Row(
                children: [
                  TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar')),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _selected != null
                        ? () => Navigator.of(context).pop(_selected)
                        : null,
                    child: const Text('Seleccionar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Client client) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar cliente'),
        content: Text('¿Eliminar a ${client.name}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<ClientsBloc>().add(DeleteClientEvent(client.id));
              },
              child:
                  const Text('Eliminar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}
