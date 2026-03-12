import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/features/pos/domain/entities/client.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/clients/clients_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/clients/clients_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/product/product_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/product/product_event.dart';

class ClientSelectionHelper {
  static Future<void> selectClientAndUpdatePrices(
    BuildContext context,
    Client? client,
  ) async {
    context.read<ClientsBloc>().add(SelectClientEvent(client));

    final int? priceListId = client?.listId;

    context.read<ProductBloc>().add(LoadProducts(priceListId: priceListId));
  }

  static Future<int> getPriceListToUse(BuildContext context) async {
    final clientsBloc = context.read<ClientsBloc>();
    return await clientsBloc.getPriceListToUse();
  }
}
