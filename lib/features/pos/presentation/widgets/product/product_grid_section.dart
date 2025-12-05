import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/features/pos/domain/entities/product.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/product/product_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/product/product_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/product/product_state.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/product/product_grid.dart';
import 'package:punto_venta_app/core/utils/utils.dart';

class ProductGridSection extends StatelessWidget {
  final void Function(Product, int, bool) onProductTap;

  const ProductGridSection({
    super.key,
    required this.onProductTap,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        if (state is ProductLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: AppDimensions.paddingM),
                Text('Cargando productos...'),
              ],
            ),
          );
        } else if (state is ProductLoaded) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = calculateCrossAxisCount(constraints.maxWidth);
              return ProductGrid(
                products: state.products,
                crossAxisCount: crossAxisCount,
                onProductTap: onProductTap,
                isLoading: false,
              );
            },
          );
        } else if (state is ProductError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.cloud_off,
                    size: 64,
                    color: Colors.amber,
                  ),
                  const SizedBox(height: AppDimensions.paddingM),
                  Text(
                    'Problema de conexión',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.amber,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimensions.paddingS),
                  Text(
                    state.message,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimensions.paddingL),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<ProductBloc>().add(LoadProducts());
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}