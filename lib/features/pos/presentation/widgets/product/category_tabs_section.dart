import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/product/product_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/product/product_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/product/product_state.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/product/category_tabs.dart';

class CategoryTabsSection extends StatelessWidget {
  final void Function(String category) onCategorySelected;
  final VoidCallback onClearSearch;

  const CategoryTabsSection({
    super.key,
    required this.onCategorySelected,
    required this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        if (state is ProductLoaded) {
          return Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: CategoryTabs(
              categories: state.categories,
              selectedCategory: state.selectedCategory,
              onCategorySelected: (category) {
                onClearSearch();
                context
                    .read<ProductBloc>()
                    .add(LoadProductsByCategory(category));
                onCategorySelected(category);
              },
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
