import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos_flutter_app/core/constants/app_colors.dart';
import 'package:pos_flutter_app/features/pos/domain/entities/client.dart';
import 'package:pos_flutter_app/features/pos/domain/usecases/complete_order_usecase.dart';
import 'package:pos_flutter_app/features/pos/presentation/bloc/cart/cart_bloc.dart';
import 'package:pos_flutter_app/features/pos/presentation/bloc/cart/cart_event.dart';
import 'package:pos_flutter_app/features/pos/presentation/bloc/cart/cart_state.dart';
import 'package:pos_flutter_app/injection_container.dart' as di;

showConfirmDialog(
    {required double total, required BuildContext context, Client? client}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Confirmar Venta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Total a cobrar: \$${total.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            const Text('¿Deseas procesar esta venta?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();

              final cartState = context.read<CartBloc>().state as CartLoaded;

              try {
                final completeOrderUsecase = di.sl<CompleteOrderUsecase>();
                await completeOrderUsecase(
                  items: cartState.items,
                  logItems: cartState.log,
                  total: cartState.total,
                  clientName: client?.name ?? null,
                  cashierName: 'Brayan',
                );
              } catch (e) {
                print('Error al guardar orden completada: $e');
              }

              context.read<CartBloc>().add(ClearCart());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Venta procesada exitosamente'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Confirmar'),
          ),
        ],
      );
    },
  );
}
