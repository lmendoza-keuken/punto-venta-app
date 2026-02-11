import 'package:flutter/material.dart';
import '../../../../../../core/constants/app_dimensions.dart';
import 'quantity_field.dart';
import 'search_field.dart';
import 'barcode_switch.dart';
import 'delete_button.dart';

typedef SearchSubmitCallback = Future<void> Function(String value);

class ResponsiveSearchLayout extends StatelessWidget {
  final TextEditingController searchController;
  final bool autofocus;
  final SearchSubmitCallback onSubmitted;
  final VoidCallback onClearSearch;
  final ValueChanged<String> onSearchChanged;

  const ResponsiveSearchLayout({
    super.key,
    required this.searchController,
    required this.onSubmitted,
    required this.onClearSearch,
    required this.onSearchChanged,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isCompact = constraints.maxWidth < 600;
      final padding = EdgeInsets.symmetric(
          horizontal:
              isCompact ? AppDimensions.paddingS : AppDimensions.paddingS);

      return Container(
        padding: padding,
        child: isCompact ? _buildCompactLayout() : _buildFullLayout(),
      );
    });
  }

  Widget _buildFullLayout() {
    return Row(
      children: [
        const QuantityField(),
        const SizedBox(width: AppDimensions.paddingM),
        Expanded(
          child: SearchField(
            controller: searchController,
            autofocus: autofocus,
            onSearchChanged: onSearchChanged,
            onClearSearch: onClearSearch,
            onSubmitted: onSubmitted,
          ),
        ),
        const SizedBox(width: AppDimensions.paddingM),
        const BarcodeSwitch(),
        const SizedBox(width: AppDimensions.paddingM),
        const DeleteButton(),
      ],
    );
  }

  Widget _buildCompactLayout() {
    return Column(
      children: [
        Row(
          children: [
            const QuantityField(),
            const SizedBox(width: AppDimensions.paddingS),
            const BarcodeSwitch(),
            const Spacer(),
            const DeleteButton(),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingS),
        SearchField(
          controller: searchController,
          autofocus: autofocus,
          onSearchChanged: onSearchChanged,
          onClearSearch: onClearSearch,
          onSubmitted: onSubmitted,
        ),
      ],
    );
  }
}
