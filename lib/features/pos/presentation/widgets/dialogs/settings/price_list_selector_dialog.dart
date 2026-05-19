import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/features/pos/data/models/price_list_type_response_model.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/price_list_types/price_list_types_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/price_list_types/price_list_types_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/price_list_types/price_list_types_state.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/product/product_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/product/product_event.dart';
import 'package:punto_venta_app/injection_container.dart' as di;

class PriceListSelectorDialog extends StatefulWidget {
  final int currentList;

  const PriceListSelectorDialog({
    super.key,
    required this.currentList,
  });

  @override
  State<PriceListSelectorDialog> createState() =>
      _PriceListSelectorDialogState();
}

class _PriceListSelectorDialogState extends State<PriceListSelectorDialog> {
  PriceListTypeResponseModel? _selectedPriceListType;

  PriceListTypeResponseModel? _findSelectedType(
      List<PriceListTypeResponseModel> types) {
    if (types.isEmpty) return null;

    return types.firstWhere(
      (type) => type.id == widget.currentList,
      orElse: () => types.firstWhere(
        (type) => type.id == 1,
        orElse: () => types.first,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PriceListTypesBloc, PriceListTypesState>(
      builder: (context, state) {
        if (state is PriceListTypesInitial || state is PriceListTypesLoading) {
          return const AlertDialog(
            content: SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        List<PriceListTypeResponseModel> availableTypes = [];
        String? errorMessage;

        if (state is PriceListTypesLoaded) {
          availableTypes = state.listTypes
              .where((type) => type.id != null)
              .toList()
            ..sort((a, b) => a.id!.compareTo(b.id!));
        } else if (state is PriceListTypesError) {
          errorMessage = state.message;
        }

        if (availableTypes.isEmpty) {
          availableTypes = List.generate(
            20,
            (index) => PriceListTypeResponseModel(
              id: index + 1,
              description: 'Lista ${index + 1}',
            ),
          );
        }

        _selectedPriceListType ??= _findSelectedType(availableTypes);

        return AlertDialog(
          title: const Text('Cambiar Lista de Precios'),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Lista actual: ${widget.currentList}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<PriceListTypeResponseModel>(
                  value: _selectedPriceListType,
                  decoration: const InputDecoration(
                    labelText: 'Seleccionar Lista',
                    border: OutlineInputBorder(),
                  ),
                  items: availableTypes
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(
                            type.description?.isNotEmpty == true
                                ? type.description!
                                : 'Lista ${type.id ?? ''}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedPriceListType = newValue;
                      });
                    }
                  },
                ),
                const SizedBox(height: 10),
                Text(
                  'Listas disponibles: ${availableTypes.length}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Los productos se recargarán con los nuevos precios',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'No se pudo cargar las listas de precios. Se muestran valores por defecto.',
                    style: TextStyle(fontSize: 11, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final selectedId =
                    _selectedPriceListType?.id ?? widget.currentList;
                if (selectedId != widget.currentList) {
                  context.read<ProductBloc>().add(ChangePriceList(selectedId));
                  Navigator.of(context).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Lista de precios cambiada a ${_selectedPriceListType?.description ?? selectedId}',
                      ),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                } else {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Aplicar'),
            ),
          ],
        );
      },
    );
  }
}

void showPriceListSelectorDialog(BuildContext context, int currentList) {
  showDialog(
    context: context,
    builder: (context) => BlocProvider.value(
      value: di.sl<PriceListTypesBloc>()..add(FetchPriceListTypesEvent()),
      child: PriceListSelectorDialog(
        currentList: currentList > 0 ? currentList : 1,
      ),
    ),
  );
}
