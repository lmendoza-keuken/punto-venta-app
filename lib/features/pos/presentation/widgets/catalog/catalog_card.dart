import 'package:flutter/material.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';

class CatalogCard extends StatelessWidget {
  final Widget searchBar;
  final Widget categoryTabs;
  final Widget productGrid;

  const CatalogCard({
    super.key,
    required this.searchBar,
    required this.categoryTabs,
    required this.productGrid,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(AppDimensions.paddingS),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          searchBar,
          categoryTabs,
          Expanded(child: productGrid),
        ],
      ),
    );
  }
}
