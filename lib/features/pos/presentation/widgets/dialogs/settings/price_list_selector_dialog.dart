import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/product/product_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/product/product_event.dart';
import 'package:punto_venta_app/features/pos/data/datasources/product_local_data_datasource.dart';
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
  late int _selectedList;
  List<int> _availableLists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedList = widget.currentList > 0 ? widget.currentList : 1;
    _loadAvailablePriceLists();
  }

  Future<void> _loadAvailablePriceLists() async {
    try {
      final dataSource = di.sl<ProductLocalDataSource>();
      final precios = await dataSource.getPreciosArticulos();
      
      final listsSet = precios.map((p) => p.listId).toSet();
      final lists = listsSet.toList()..sort();
      
      setState(() {
        _availableLists = lists;
        _isLoading = false;
        
        if (!_availableLists.contains(_selectedList)) {
          _selectedList = _availableLists.contains(1) 
              ? 1 
              : (_availableLists.isNotEmpty ? _availableLists.first : 1);
        }
      });
    } catch (e) {
      setState(() {
        _availableLists = List.generate(20, (index) => index + 1);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AlertDialog(
        content: SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

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
            DropdownButtonFormField<int>(
              value: _selectedList,
              decoration: const InputDecoration(
                labelText: 'Seleccionar Lista',
                border: OutlineInputBorder(),
              ),
              items: _availableLists
                  .map((list) => DropdownMenuItem(
                        value: list,
                        child: Text('Lista $list'),
                      ))
                  .toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedList = newValue;
                  });
                }
              },
            ),
            const SizedBox(height: 10),
            Text(
              'Listas disponibles: ${_availableLists.length}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 5),
            const Text(
              'Los productos se recargarán con los nuevos precios',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
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
            if (_selectedList != widget.currentList) {
              context.read<ProductBloc>().add(ChangePriceList(_selectedList));
              Navigator.of(context).pop();
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Lista de precios cambiada a $_selectedList'),
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
  }
}

void showPriceListSelectorDialog(BuildContext context, int currentList) {
  showDialog(
    context: context,
    builder: (context) => PriceListSelectorDialog(
      currentList: currentList > 0 ? currentList : 1, 
    ),
  );
}