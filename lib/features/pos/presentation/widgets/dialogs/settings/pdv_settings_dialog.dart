import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/features/pos/domain/entities/pdv_config.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/pdv_config/pdv_config_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/pdv_config/pdv_config_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/pdv_config/pdv_config_state.dart';
import 'package:punto_venta_app/injection_container.dart' as di;

Future<({int pdvId, int sucursalId})?> showPdvSettingsDialog(
    BuildContext context) async {
  return await showDialog<({int pdvId, int sucursalId})>(
    context: context,
    builder: (ctx) => BlocProvider(
      create: (_) => di.sl<PdvConfigBloc>()..add(FetchPdvConfigEvent()),
      child: const _PdvSettingsDialogContent(),
    ),
  );
}

class _PdvSettingsDialogContent extends StatefulWidget {
  const _PdvSettingsDialogContent();

  @override
  State<_PdvSettingsDialogContent> createState() =>
      _PdvSettingsDialogContentState();
}

class _PdvSettingsDialogContentState extends State<_PdvSettingsDialogContent> {
  final formKey = GlobalKey<FormState>();
  late TextEditingController pdvIdController;
  late TextEditingController branchIdController;
  late TextEditingController branchNumberController;
  
  List<Branch> _branches = [];
  Branch? _selectedBranch;

  @override
  void initState() {
    super.initState();
    pdvIdController = TextEditingController();
    branchIdController = TextEditingController();
    branchNumberController = TextEditingController();
  }

  @override
  void dispose() {
    pdvIdController.dispose();
    branchIdController.dispose();
    branchNumberController.dispose();
    super.dispose();
  }

  void _updateControllersFromConfig(PdvConfig config, List<Branch> branches) {
    pdvIdController.text = config.pdvId?.toString() ?? '';
    branchIdController.text = config.branchId?.toString() ?? '';
    branchNumberController.text = config.branchNumber ?? "";
    
    _branches = branches;
    
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
  }
  
  void _onBranchSelected(Branch? branch) {
    setState(() {
      _selectedBranch = branch;
      if (branch != null) {
        branchIdController.text = branch.id.toString();
      }
    });
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 8),
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
        final isLoading = state is PdvConfigLoading || state is BranchesLoading;

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
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              size: 20, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isLoading
                                  ? 'Cargando configuración...'
                                  : 'Configura los datos de tu punto de venta',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
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
                      // Campo: PDV ID
                      TextFormField(
                        controller: pdvIdController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'ID del PDV',
                          hintText: '1',
                          prefixIcon: Icon(Icons.store),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Ingresa el ID del PDV';
                          }
                          final parsedValue = int.tryParse(v);
                          if (parsedValue == null) {
                            return 'Debe ser un número';
                          }
                          if (parsedValue <= 0) {
                            return 'Debe ser mayor a 0';
                          }
                          return null;
                        },
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
                      TextFormField(
                        controller: branchNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Número de Sucursal',
                          hintText: 'Sucursal Centro',
                          prefixIcon: Icon(Icons.tag),
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Color(0xFFF5F5F5),
                        ),
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(4),
                        ],
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Ingresa el número de sucursal';
                          }
                          return null;
                        },
                      ),
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

                      final pdvId = int.parse(pdvIdController.text.trim());
                      final branchId =
                          int.parse(branchIdController.text.trim());
                      final branchNumber = branchNumberController.text.trim();

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
