import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_state.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/product/search_bar.dart/search_helpers.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/product/search_bar.dart/search_layout.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_bloc.dart';

class EnhancedSearchBar extends StatefulWidget {
  final TextEditingController searchController;
  final Function(String) onSearchChanged;
  final VoidCallback onClearSearch;

  final bool autofocus;

  const EnhancedSearchBar({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClearSearch,
    this.autofocus = false,
  });

  @override
  State<EnhancedSearchBar> createState() => _EnhancedSearchBarState();
}

class _EnhancedSearchBarState extends State<EnhancedSearchBar> {
  final TextEditingController _quantityController =
      TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    context.read<UiBloc>().stream.listen((state) {
      if (state is UiLoaded && state.selectedQuantity == 1) {
        if (_quantityController.text != '1') {
          _quantityController.text = '1';
        }
      }
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveSearchLayout(
      searchController: widget.searchController,
      autofocus: widget.autofocus,
      onSearchChanged: widget.onSearchChanged,
      onClearSearch: widget.onClearSearch,
      onSubmitted: (value) => SearchProcessor.processCode(
        context: context,
        rawCode: value,
        searchController: widget.searchController,
        onClearSearch: widget.onClearSearch,
      ),
    );
  }
}
