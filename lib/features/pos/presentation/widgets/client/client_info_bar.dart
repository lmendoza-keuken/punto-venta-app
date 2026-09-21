import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/core/constants/app_string.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/clients/clients_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/clients/clients_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/clients/clients_state.dart';

class ClientInfoBar extends StatelessWidget {
  const ClientInfoBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClientsBloc, ClientsState>(
      buildWhen: (previous, current) {
        if (previous is ClientsLoaded && current is ClientsLoaded) {
          return previous.selectedClient?.id != current.selectedClient?.id ||
              previous.defaultClient?.id != current.defaultClient?.id;
        }
        return previous.runtimeType != current.runtimeType;
      },
      builder: (context, state) {
        if (state is! ClientsLoaded ||
            state.selectedClient == null ||
            state.defaultClient == null ||
            state.selectedClient!.id == state.defaultClient!.id) {
          return const SizedBox.shrink();
        }

        final client = state.selectedClient!;

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
              const Text(
                AppStrings.selectedClient,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppDimensions.paddingM),
              Expanded(
                child: Text(
                  '${client.name}${client.document != null ? ' • ${client.document}' : ''}',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  context.read<ClientsBloc>().add(ResetToDefaultClientEvent());
                },
                icon: const Icon(Icons.person_off_outlined, size: 18),
                label: const Text(AppStrings.resetToDefaultClient),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingS,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
