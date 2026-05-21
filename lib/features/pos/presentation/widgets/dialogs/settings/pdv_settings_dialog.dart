import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/features/pos/domain/entities/pdv_config.dart';
import 'package:punto_venta_app/features/pos/domain/entities/client.dart';
import 'package:punto_venta_app/features/pos/domain/repositories/pdv_config_repository.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/fetch_branches_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/fetch_pdv_config_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/get_vat_categories_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/get_clients_usecase.dart';
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

  @override
  State<_PdvSettingsDialogContent> createState() =>
      _PdvSettingsDialogContentState();
}

class _PdvSettingsDialogContentState extends State<_PdvSettingsDialogContent> {
  final formKey = GlobalKey<FormState>();
  late TextEditingController pdvIdController;
  late TextEditingController branchIdController;
  // late TextEditingController branchNumberController;
  final TextEditingController _clientSearchController = TextEditingController();
  
  List<Branch> _branches = [];
  Branch? _selectedBranch;
  
  List<Client>? _clients;
  Client? _selectedClient;
  String _clientSearchQuery = '';
  String? _localError;
  PdvConfig? _pdvConfig;

  @override
  void initState() {
    super.initState();
    pdvIdController = TextEditingController();
    branchIdController = TextEditingController();
    // branchNumberController = TextEditingController();
    _loadClients();
  }

  Future<void> _loadClients() async {
    try {
      final getClientsUsecase = di.sl<GetClientsUsecase>();
      final clients = await getClientsUsecase();
      setState(() {
        _clients = clients;
        if(_pdvConfig != null) {
          _updateControllersFromConfig(_pdvConfig!, _branches);
        }
      });
    } catch (e) {
      print('Error loading clients: $e');
    }
  }

  @override
  void dispose() {
    pdvIdController.dispose();
    branchIdController.dispose();
    // branchNumberController.dispose();
    _clientSearchController.dispose();
    super.dispose();
  }

  void _updateControllersFromConfig(PdvConfig config, List<Branch> branches) {
    setState(() {
      pdvIdController.text = config.pdvId?.toString() ?? '';
      branchIdController.text = config.branchId?.toString() ?? '';
      // branchNumberController.text = config.branchNumber ?? "";
      
      _branches = branches;
      _pdvConfig = config;
      
      // Seleccionar la sucursal actual
      if (config.branchId != null) {
        Branch? matchedBranch;
        for (final branch in branches) {
          if (branch.id == config.branchId) {
            matchedBranch = branch;
            break;
          }
        }
        _selectedBranch = matchedBranch ?? (branches.isNotEmpty ? branches.first : null);
      }

      // Seleccionar el cliente default (pdvId = delivery_location_id = client id)
      if (config.pdvId != null && _clients?.isNotEmpty == true) {
        Client? matchedClient;
        for (final client in _clients!) {
          if (client.id == config.pdvId) {
            matchedClient = client;
            break;
          }
        }
        _selectedClient = matchedClient;
      }
    });
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

  List<Client> get _filteredClients {
    if (_clientSearchQuery.isEmpty) {
      return _clients!;
    }
    return _clients!.where((client) {
      final query = _clientSearchQuery.toLowerCase();
      return client.name.toLowerCase().contains(query) ||
          client.id.toString().contains(query) ||
          (client.document?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PdvConfigBloc, PdvConfigState>(
      listener: (context, state) {
        if (state is PdvConfigLoaded) {
          _updateControllersFromConfig(state.config, state.branches);
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
          setState(() {
            _localError = null; // Clear local error if we got a bloc error
          });
        }
      },
      builder: (context, state) {
        final isLoading = state is PdvConfigLoading || state is BranchesLoading || _clients == null;

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
                    // Banner de información
                    // Banner de información o Error
                    Builder(
                      builder: (context) {
                        final String message;
                        final Color bgColor;
                        final Color borderColor;
                        final IconData icon;
                        final Color accentColor;

                        if (state is PdvConfigError || _localError != null) {
                          message = (state is PdvConfigError) ? state.message : _localError!;
                          bgColor = Colors.red.shade50;
                          borderColor = Colors.red.shade200;
                          icon = Icons.error_outline;
                          accentColor = Colors.red;
                        } else {
                          message = isLoading
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
                                    fontWeight: (state is PdvConfigError || _localError != null) 
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

                    if (isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else ...[
                      // Campo: Cliente Default (PDV ID = delivery_location_id = Client ID)
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
                            TextFormField(
                              controller: _clientSearchController,
                              decoration: InputDecoration(
                                labelText: 'Buscar cliente',
                                hintText: 'Nombre, ID o documento',
                                prefixIcon: const Icon(Icons.search),
                                border: const OutlineInputBorder(),
                                suffixIcon: _clientSearchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          setState(() {
                                            _clientSearchController.clear();
                                            _clientSearchQuery = '';
                                          });
                                        },
                                      )
                                    : null,
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _clientSearchQuery = value;
                                });
                              },
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              height: 200,
                              child: _filteredClients.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'No se encontraron clientes',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: _filteredClients.length,
                                      itemBuilder: (context, index) {
                                        final client = _filteredClients[index];
                                        final isSelected =
                                            _selectedClient?.id == client.id;

                                        return ListTile(
                                          selected: isSelected,
                                          selectedTileColor:
                                              AppColors.primary.withValues(alpha: 0.1),
                                          leading: CircleAvatar(
                                            backgroundColor: isSelected
                                                ? AppColors.primary
                                                : Colors.grey.shade300,
                                            child: Icon(
                                              Icons.person,
                                              color: isSelected
                                                  ? Colors.white
                                                  : Colors.grey.shade600,
                                            ),
                                          ),
                                          title: Text(
                                            client.name,
                                            style: TextStyle(
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                          subtitle: Text('ID: ${client.id}${client.document != null ? ' - ${client.document}' : ''}'),
                                          trailing: isSelected
                                              ? const Icon(
                                                  Icons.check_circle,
                                                  color: AppColors.primary,
                                                )
                                              : null,
                                          onTap: () => _onClientSelected(client),
                                        );
                                      },
                                    ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (_selectedClient != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green.shade200),
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
                                border: Border.all(color: Colors.orange.shade200),
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
                                border: Border.all(color: Colors.red.shade200),
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
                      // Dropdown: Selección de Sucursal
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
                      // Campo: Sucursal ID (readonly, populated by dropdown)
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
                      // TextFormField(
                      //   controller: branchNumberController,
                      //   readOnly: !widget.isAdmin,
                      //   decoration: const InputDecoration(
                      //     labelText: 'Número de Sucursal',
                      //     hintText: 'Sucursal Centro',
                      //     prefixIcon: Icon(Icons.tag),
                      //     border: OutlineInputBorder(),
                      //     filled: true,
                      //     fillColor: Color(0xFFF5F5F5),
                      //   ),
                      //   inputFormatters: [
                      //     LengthLimitingTextInputFormatter(4),
                      //   ],
                      //   validator: (v) {
                      //     if (v == null || v.isEmpty) {
                      //       return 'Ingresa el número de sucursal';
                      //     }
                      //     return null;
                      //   },
                      // ),
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
              onPressed: isLoading
                  ? null
                  : () {
                      if (!formKey.currentState!.validate()) return;

                      // Validar que se haya seleccionado un cliente default
                      if (_selectedClient == null) {
                        setState(() {
                          _localError = 'Debes seleccionar un cliente default';
                        });
                        return;
                      }

                      setState(() {
                        _localError = null;
                      });

                      // El pdvId es el ID del cliente seleccionado (delivery_location_id)
                      final pdvId = _selectedClient!.id;
                      final branchId =
                          int.parse(branchIdController.text.trim());
                      final branchNumber = "";//branchNumberController.text.trim();

                      final newConfig = PdvConfig(
                        pdvId: pdvId,
                        branchId: branchId,
                        branchNumber: branchNumber,
                      );

                      context
                          .read<PdvConfigBloc>()
                          .add(SavePdvConfigEvent(newConfig));
                    },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }
}
