import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/core/constants/app_string.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/clients/clients_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/clients/clients_state.dart';

class ClientInfoBar extends StatelessWidget {
  const ClientInfoBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingM,
        vertical: AppDimensions.paddingS,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            AppStrings.selectedClient,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: AppDimensions.paddingM),
          Expanded(
            child: BlocBuilder<ClientsBloc, ClientsState>(
              builder: (context, state) {
                if (state is ClientsLoaded && state.selectedClient != null) {
                  final c = state.selectedClient!;
                  return Text(
                    '${c.name} ${c.document != null ? '• ${c.document}' : ''}',
                    style: const TextStyle(fontSize: 14),
                  );
                }
                return Text(
                  AppStrings.noClientSelected,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}