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
        height: 480,
        child: Column(
          children: [
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
                    return Center(child: Text('Error: ${state.message}'));
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
