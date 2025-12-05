import 'package:flutter/material.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/product/search_bar.dart/enchanced_search_bar.dart';

class IntegratedSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final bool autofocus;

  const IntegratedSearchBar({
    super.key,
    required this.controller,
    required this.onSearchChanged,
    required this.onClearSearch,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingS),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: EnhancedSearchBar(
        searchController: controller,
        onSearchChanged: onSearchChanged,
        onClearSearch: onClearSearch,
        autofocus: autofocus,
      ),
    );
  }
}