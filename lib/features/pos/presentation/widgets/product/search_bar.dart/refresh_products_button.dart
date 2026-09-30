import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/product/product_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/product/product_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/product/product_state.dart';

class RefreshProductsButton extends StatelessWidget {
  const RefreshProductsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        final isLoading = state is ProductLoading;

        return Tooltip(
          message: 'Recargar productos',
          child: Container(
            width: AppDimensions.buttonHeightm,
            height: AppDimensions.buttonHeightm,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimensions.borderRadiusM),
              border: Border.all(
                color: Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius:
                    BorderRadius.circular(AppDimensions.borderRadiusM),
                onTap: isLoading
                    ? null
                    : () {
                        context.read<ProductBloc>().add(
                              const LoadProducts(forceRefresh: true),
                            );
                      },
                child: isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(
                        Icons.refresh,
                        color: AppColors.textSecondary,
                        size: 24,
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}
