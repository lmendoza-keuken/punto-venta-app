import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/features/pos/domain/entities/client.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/constants/app_dimensions.dart';
import '../../../bloc/clients/clients_bloc.dart';
import '../../../bloc/clients/clients_event.dart';
import '../../../bloc/clients/clients_state.dart';
import '../../../utils/client_selection_helper.dart';

class SelectClientDialog extends StatefulWidget {
  const SelectClientDialog({super.key});

  static const double _listHeight = 400;

  @override
  State<SelectClientDialog> createState() => _SelectClientDialogState();
}

class _SelectClientDialogState extends State<SelectClientDialog> {
  Client? _selected;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    context.read<ClientsBloc>().add(LoadClients());
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _searchQuery = value.toLowerCase());
    });
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() => _searchQuery = '');
  }

  List<Client> _filterClients(List<Client> allClients) {
    if (_searchQuery.isEmpty) return allClients;
    return allClients.where((client) {
      final name = client.name.toLowerCase();
      final document = client.document?.toLowerCase() ?? '';
      return name.contains(_searchQuery) || document.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      title: Row(
        children: [
          const Icon(Icons.person_search, color: AppColors.primary),
          const SizedBox(width: AppDimensions.paddingS),
          Text('Seleccionar Cliente',
              style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: _selected != null
              ? () => Navigator.of(context).pop(_selected)
              : null,
          child: const Text('Seleccionar'),
        ),
      ],
      content: SizedBox(
        width: 500,
        height: (MediaQuery.of(context).size.height * 0.6).clamp(300.0, 550.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CurrentClientHeader(onClearSelected: () async {
              await ClientSelectionHelper.selectClientAndUpdatePrices(
                  context, null);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cliente deseleccionado - Consumidor Final'),
                  backgroundColor: AppColors.warning,
                  duration: Duration(seconds: 2),
                ),
              );
            }),
            const Divider(),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _searchController,
              builder: (context, value, _) {
                return TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre o documento...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: value.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: _clearSearch,
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 14),
                  onChanged: _onSearchChanged,
                );
              },
            ),
            const SizedBox(height: AppDimensions.paddingS),
            Expanded(
              child: BlocBuilder<ClientsBloc, ClientsState>(
                buildWhen: (previous, current) {
                  if (previous.runtimeType != current.runtimeType) {
                    return true;
                  }
                  if (previous is ClientsLoaded && current is ClientsLoaded) {
                    return previous.clients != current.clients;
                  }
                  return true;
                },
                builder: (context, state) {
                  if (state is ClientsLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is ClientsLoaded) {
                    return _ClientsListView(
                      allClients: state.clients,
                      filteredClients: _filterClients(state.clients),
                      selected: _selected,
                      onSelect: (client) => setState(() => _selected = client),
                      onDelete: _confirmDelete,
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
                context
                    .read<ClientsBloc>()
                    .add(DeleteClientEvent(client.id.toString()));
              },
              child:
                  const Text('Eliminar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}

class _CurrentClientHeader extends StatelessWidget {
  final VoidCallback onClearSelected;

  const _CurrentClientHeader({required this.onClearSelected});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClientsBloc, ClientsState>(
      buildWhen: (previous, current) {
        if (previous is ClientsLoaded && current is ClientsLoaded) {
          return previous.selectedClient != current.selectedClient;
        }
        return previous.runtimeType != current.runtimeType;
      },
      builder: (context, state) {
        final selectedClient =
            state is ClientsLoaded ? state.selectedClient : null;

        return Container(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
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
                selectedClient == null ? Icons.person_off : Icons.person,
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
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    if (selectedClient != null) ...[
                      Text(
                        selectedClient.name,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
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
                            style: Theme.of(context).textTheme.bodyMedium,
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
                  onPressed: onClearSelected,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ClientsListView extends StatelessWidget {
  final List<Client> allClients;
  final List<Client> filteredClients;
  final Client? selected;
  final ValueChanged<Client> onSelect;
  final ValueChanged<Client> onDelete;

  const _ClientsListView({
    required this.allClients,
    required this.filteredClients,
    required this.selected,
    required this.onSelect,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (allClients.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person, color: AppColors.addClientButton),
            Text('No hay clientes guardados'),
          ],
        ),
      );
    }

    if (filteredClients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No se encontraron clientes',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta con otro término de búsqueda',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredClients.length,
      itemBuilder: (context, index) {
        final client = filteredClients[index];
        return _ClientListTile(
          key: ValueKey(client.id),
          client: client,
          isSelected: selected?.id == client.id,
          onTap: () => onSelect(client),
          onDelete: () => onDelete(client),
        );
      },
    );
  }
}

class _ClientListTile extends StatelessWidget {
  final Client client;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ClientListTile({
    super.key,
    required this.client,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingS),
      color: isSelected ? AppColors.primary.withOpacity(0.08) : null,
      child: ListTile(
        title: Text(client.name),
        subtitle: Text(
          '${client.document ?? ''}${client.phone != null ? ' • ${client.phone}' : ''}',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: AppColors.error),
          onPressed: onDelete,
        ),
        onTap: onTap,
      ),
    );
  }
}
