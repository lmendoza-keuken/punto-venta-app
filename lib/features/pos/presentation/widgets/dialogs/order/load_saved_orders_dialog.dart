import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/core/utils/extensions.dart';
import 'package:punto_venta_app/features/pos/domain/entities/saved_order.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/saved_orders/saved_orders_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/saved_orders/saved_orders_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/saved_orders/saved_orders_state.dart';

class LoadSavedOrdersDialog extends StatefulWidget {
  const LoadSavedOrdersDialog({super.key});

  @override
  State<LoadSavedOrdersDialog> createState() => _LoadSavedOrdersDialogState();
}

class _LoadSavedOrdersDialogState extends State<LoadSavedOrdersDialog> {
  SavedOrder? selectedOrder;

  @override
  void initState() {
    super.initState();
    context.read<SavedOrdersBloc>().add(LoadSavedOrders());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SavedOrdersBloc, SavedOrdersState>(
      listener: (context, state) {
        if (state is OrderDeleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          // Reset selected order if it was deleted
          setState(() {
            selectedOrder = null;
          });
        } else if (state is SavedOrdersError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.restore, color: AppColors.primary),
            SizedBox(width: AppDimensions.paddingS),
            Text('Reanudar Pedido'),
          ],
        ),
        content: SizedBox(
          width: 600,
          height: 400,
          child: BlocBuilder<SavedOrdersBloc, SavedOrdersState>(
            builder: (context, state) {
              if (state is SavedOrdersLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is SavedOrdersLoaded) {
                if (state.orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: AppDimensions.paddingM),
                        Text(
                          'No hay pedidos guardados',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    // Lista de pedidos
                    Expanded(
                      child: ListView.builder(
                        itemCount: state.orders.length,
                        itemBuilder: (context, index) {
                          final order = state.orders[index];
                          final isSelected = selectedOrder?.id == order.id;

                          return Card(
                            margin: const EdgeInsets.only(
                                bottom: AppDimensions.paddingS),
                            color: isSelected
                                ? AppColors.primary.withOpacity(0.1)
                                : null,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primary,
                                child: Text(
                                  order.items.length.toString(),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(
                                order.name,
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      'Total: \$ ${order.total.formatToCurrency()}'),
                                  Text(
                                      'Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt)}'),
                                  if (order.clientName != null)
                                    Text('Cliente: ${order.clientName}'),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete,
                                    color: AppColors.error),
                                onPressed: () => _deleteOrder(order),
                              ),
                              onTap: () {
                                setState(() {
                                  selectedOrder = isSelected ? null : order;
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),

                    // Información del pedido seleccionado
                    if (selectedOrder != null)
                      Container(
                        margin:
                            const EdgeInsets.only(top: AppDimensions.paddingM),
                        padding: const EdgeInsets.all(AppDimensions.paddingM),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                              AppDimensions.borderRadiusM),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Artículos en el pedido:',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 60,
                              child: ListView.builder(
                                itemCount: selectedOrder!.items.length,
                                itemBuilder: (context, index) {
                                  final item = selectedOrder!.items[index];
                                  return Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 2),
                                    child: Text(
                                      '• ${item.product.name} (x${item.quantity})',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              } else if (state is SavedOrdersError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, color: AppColors.error, size: 64),
                      const SizedBox(height: AppDimensions.paddingM),
                      Text(
                        'Error al cargar pedidos',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppDimensions.paddingS),
                      Text(state.message),
                      const SizedBox(height: AppDimensions.paddingM),
                      ElevatedButton(
                        onPressed: () {
                          context
                              .read<SavedOrdersBloc>()
                              .add(LoadSavedOrders());
                        },
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: selectedOrder != null
                ? () => Navigator.of(context).pop(selectedOrder)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cargar Pedido'),
          ),
        ],
      ),
    );
  }

  void _deleteOrder(SavedOrder order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Pedido'),
        content: Text('¿Estás seguro de que quieres eliminar "${order.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<SavedOrdersBloc>().add(DeleteSavedOrder(order.id));
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
