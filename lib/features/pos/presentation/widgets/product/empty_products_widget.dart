import 'package:flutter/material.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';

class EmptyProducts extends StatelessWidget {
  const EmptyProducts({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: AppDimensions.paddingM),
            Text(
              'No se encontraron productos',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: AppDimensions.paddingS),
            Text(
              'Intenta cambiar los filtros o la búsqueda',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade500,
                  ),
            ),
          ],
        ),
      );
  }
}