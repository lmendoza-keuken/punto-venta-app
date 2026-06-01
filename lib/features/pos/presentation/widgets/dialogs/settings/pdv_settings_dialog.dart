import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/features/pos/domain/entities/pdv_config.dart';
import 'package:punto_venta_app/features/pos/domain/entities/client.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/pdv_config_repository.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/fetch_branches_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/fetch_pdv_config_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/get_vat_categories_usecase.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/clients/clients_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/clients/clients_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/clients/clients_state.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/pdv_config/pdv_config_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/pdv_config/pdv_config_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/pdv_config/pdv_config_state.dart';
import 'package:punto_venta_app/injection_container.dart' as di;

Future<({int pdvId, int sucursalId})?> showPdvSettingsDialog(
    BuildContext context, bool isAdmin) async {
  return await showDialog<({int pdvId, int sucursalId})>(
    context: context,
    builder: (ctx) => BlocProvider(
      create: (_) => PdvConfigBloc(
        fetchPdvConfigUsecase: di.sl<FetchPdvConfigUsecase>(),
        fetchBranchesUsecase: di.sl<FetchBranchesUsecase>(),
        getVatCategoriesUsecase: di.sl<GetVatCategoriesUsecase>(),
        repository: di.sl<PdvConfigRepository>(),
      )..add(FetchPdvConfigEvent()),
      child: _PdvSettingsDialogContent(isAdmin),
    ),
  );
}

class _PdvSettingsDialogContent extends StatefulWidget {
  final bool isAdmin;
  const _PdvSettingsDialogContent(this.isAdmin);

  static const double clientListHeight = 200;

  @override
  State<_PdvSettingsDialogContent> createState() =>
      _PdvSettingsDialogContentState();
}

class _PdvSettingsDialogContentState extends State<_PdvSettingsDialogContent> {
  final formKey = GlobalKey<FormState>();
  late TextEditingController pdvIdController;
  late TextEditingController branchIdController;
  final TextEditingController _clientSearchController = TextEditingController();
  Timer? _searchDebounce;

  List<Branch> _branches = [];
  Branch? _selectedBranch;

  List<Client> _clients = [];
  bool _isClientsLoading = true;
  Client? _selectedClient;
  String _clientSearchQuery = '';
  String? _localError;
  PdvConfig? _pdvConfig;

  @override
  void initState() {
    super.initState();
    pdvIdController = TextEditingController();
    branchIdController = TextEditingController();

    final clientsState = context.read<ClientsBloc>().state;
    if (clientsState is ClientsLoaded) {
      _clients = clientsState.clients;
      _isClientsLoading = false;
    }
    context.read<ClientsBloc>().add(LoadClients());
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    pdvIdController.dispose();
    branchIdController.dispose();
    _clientSearchController.dispose();
    super.dispose();
  }

  void _onClientsState(ClientsState state) {
    if (state is ClientsLoaded) {
      setState(() {
        _clients = state.clients;
        _isClientsLoading = false;
        _syncSelectedClientFromConfig();
      });
    } else if (state is ClientsLoading) {
      if (_clients.isEmpty) {
        setState(() => _isClientsLoading = true);
      }
    } else if (state is ClientsError) {
      setState(() => _isClientsLoading = false);
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _clientSearchQuery = value.toLowerCase());
    });
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _clientSearchController.clear();
    setState(() => _clientSearchQuery = '');
  }

  List<Client> _filterClients(List<Client> clients) {
    if (_clientSearchQuery.isEmpty) return clients;
    return clients.where((client) {
      return client.name.toLowerCase().contains(_clientSearchQuery) ||
          client.id.toString().contains(_clientSearchQuery) ||
          (client.document?.toLowerCase().contains(_clientSearchQuery) ?? false);
    }).toList();
  }

  void _updateControllersFromConfig(PdvConfig config, List<Branch> branches) {
    pdvIdController.text = config.pdvId?.toString() ?? '';
    branchIdController.text = config.branchId?.toString() ?? '';

    _branches = branches;
    _pdvConfig = config;

    if (config.branchId != null) {
      Branch? matchedBranch;
      for (final branch in branches) {
        if (branch.id == config.branchId) {
          matchedBranch = branch;
          break;
        }
      }
      _selectedBranch =
          matchedBranch ?? (branches.isNotEmpty ? branches.first : null);
    }

    _syncSelectedClientFromConfig();
  }

  void _syncSelectedClientFromConfig() {
    if (_pdvConfig?.pdvId == null || _clients.isEmpty) return;

    Client? matchedClient;
    for (final client in _clients) {
      if (client.id == _pdvConfig!.pdvId) {
        matchedClient = client;
        break;
      }
    }
    _selectedClient = matchedClient;
  }

  void _onBranchSelected(Branch? branch) {
    setState(() {
      _selectedBranch = branch;
      if (branch != null) {
        branchIdController.text = branch.id.toString();
      }
    });
  }

  void _onClientSelected(Client? client) {
    setState(() {
      _selectedClient = client;
      if (client != null) {
        pdvIdController.text = client.id.toString();
      }
    });
  }

  Widget _buildClientList() {
    if (_isClientsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredClients = _filterClients(_clients);

    if (_clients.isEmpty) {
      return const Center(
        child: Text(
          'No hay clientes disponibles',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    if (filteredClients.isEmpty) {
      return const Center(
        child: Text(
          'No se encontraron clientes',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredClients.length,
      itemBuilder: (context, index) {
        final client = filteredClients[index];
        final isSelected = _selectedClient?.id == client.id;

        return _PdvClientListTile(
          key: ValueKey(client.id),
          client: client,
          isSelected: isSelected,
          onTap: () => _onClientSelected(client),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ClientsBloc, ClientsState>(
      listener: (context, state) => _onClientsState(state),
      child: BlocConsumer<PdvConfigBloc, PdvConfigState>(
        listener: (context, state) {
          if (state is PdvConfigLoaded) {
            setState(() {
              _updateControllersFromConfig(state.config, state.branches);
            });
          } else if (state is PdvConfigSaved) {
            Navigator.of(context).pop(
              (pdvId: state.config.pdvId, sucursalId: state.config.branchId),
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Configuración del PDV guardada'),
                  ],
                ),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is PdvConfigError) {
            setState(() => _localError = null);
          }
        },
        builder: (context, state) {
          final isConfigLoading =
              state is PdvConfigLoading || state is BranchesLoading;
          final canSave = !isConfigLoading && !_isClientsLoading;

          return AlertDialog(
            title: const Text('Configuración del PDV'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: SizedBox(
                  width: 420,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Builder(
                        builder: (context) {
                          final String message;
                          final Color bgColor;
                          final Color borderColor;
                          final IconData icon;
                          final Color accentColor;

                          if (state is PdvConfigError || _localError != null) {
                            message = (state is PdvConfigError)
                                ? state.message
                                : _localError!;
                            bgColor = Colors.red.shade50;
                            borderColor = Colors.red.shade200;
                            icon = Icons.error_outline;
                            accentColor = Colors.red;
                          } else {
                            message = isConfigLoading
                                ? 'Cargando configuración...'
                                : 'Configura los datos de tu punto de venta';
                            bgColor = Colors.blue.shade50;
                            borderColor = Colors.blue.shade200;
                            icon = Icons.info_outline;
                            accentColor = Colors.blue;
                          }

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              children: [
                                Icon(icon, size: 20, color: accentColor),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    message,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: accentColor.withValues(alpha: 0.9),
                                      fontWeight: (state is PdvConfigError ||
                                              _localError != null)
                                          ? FontWeight.w500
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: AppDimensions.paddingM),
                      if (isConfigLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Cliente Default',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (widget.isAdmin) ...[
                              ValueListenableBuilder<TextEditingValue>(
                                valueListenable: _clientSearchController,
                                builder: (context, value, _) {
                                  return TextFormField(
                                    controller: _clientSearchController,
                                    decoration: InputDecoration(
                                      labelText: 'Buscar cliente',
                                      hintText: 'Nombre, ID o documento',
                                      prefixIcon: const Icon(Icons.search),
                                      border: const OutlineInputBorder(),
                                      suffixIcon: value.text.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(Icons.clear),
                                              onPressed: _clearSearch,
                                            )
                                          : null,
                                    ),
                                    onChanged: _onSearchChanged,
                                  );
                                },
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                height: _PdvSettingsDialogContent.clientListHeight,
                                child: _buildClientList(),
                              ),
                              const SizedBox(height: 8),
                            ],
                            if (_selectedClient != null)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: Colors.green.shade200),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle,
                                        size: 20, color: Colors.green),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Cliente seleccionado: ${_selectedClient!.name} [${_selectedClient!.id}]',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else if (widget.isAdmin)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: Colors.orange.shade200),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.warning_amber,
                                        size: 20, color: Colors.orange),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Selecciona un cliente default',
                                        style: TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: Colors.red.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline,
                                        size: 20, color: Colors.red.shade700),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'No se ha guardado el Cliente Default. Por favor, pide a un Admin que lo configure.',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.red.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.paddingM),
                        DropdownButtonFormField<Branch>(
                          value: _selectedBranch,
                          decoration: const InputDecoration(
                            labelText: 'Seleccionar Sucursal',
                            prefixIcon: Icon(Icons.business),
                            border: OutlineInputBorder(),
                          ),
                          items: _branches.map((branch) {
                            return DropdownMenuItem<Branch>(
                              value: branch,
                              child: Text(branch.name),
                            );
                          }).toList(),
                          onChanged: _onBranchSelected,
                          validator: (v) {
                            if (v == null) {
                              return 'Selecciona una sucursal';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppDimensions.paddingM),
                        TextFormField(
                          controller: branchIdController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'ID de Sucursal',
                            prefixIcon: Icon(Icons.location_on),
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Color(0xFFF5F5F5),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Selecciona una sucursal';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppDimensions.paddingM),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: canSave
                    ? () {
                        if (!formKey.currentState!.validate()) return;

                        if (_selectedClient == null) {
                          setState(() {
                            _localError =
                                'Debes seleccionar un cliente default';
                          });
                          return;
                        }

                        setState(() => _localError = null);

                        final pdvId = _selectedClient!.id;
                        final branchId =
                            int.parse(branchIdController.text.trim());

                        final newConfig = PdvConfig(
                          pdvId: pdvId,
                          branchId: branchId,
                          branchNumber: '',
                        );

                        context
                            .read<PdvConfigBloc>()
                            .add(SavePdvConfigEvent(newConfig));
                      }
                    : null,
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PdvClientListTile extends StatelessWidget {
  final Client client;
  final bool isSelected;
  final VoidCallback onTap;

  const _PdvClientListTile({
    super.key,
    required this.client,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      selected: isSelected,
      selectedTileColor: AppColors.primary.withValues(alpha: 0.1),
      leading: CircleAvatar(
        backgroundColor:
            isSelected ? AppColors.primary : Colors.grey.shade300,
        child: Icon(
          Icons.person,
          color: isSelected ? Colors.white : Colors.grey.shade600,
        ),
      ),
      title: Text(
        client.name,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        'ID: ${client.id}${client.document != null ? ' - ${client.document}' : ''}',
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppColors.primary)
          : null,
      onTap: onTap,
    );
  }
}
