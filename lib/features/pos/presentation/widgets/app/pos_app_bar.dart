import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/core/constants/app_string.dart';
import 'package:punto_venta_app/core/dialogs/logout_dialog.dart';
import 'package:punto_venta_app/features/auth/domain/entities/user.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/clients/clients_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/product/product_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/product/product_state.dart';
import 'package:punto_venta_app/core/widgets/dynamic_date_time.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/dialogs/settings/settings_dialog.dart';

class PosAppBar extends StatelessWidget implements PreferredSizeWidget {
  final User? user;

  const PosAppBar({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(AppStrings.keukenName, style: TextStyle(fontSize: 14),),
                  Text(
                    AppStrings.keukenDesc,
                    style: TextStyle(
                      color: AppColors.selectClientButton,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (constraints.maxWidth > 600) ...[
                Text(
                  'Cajero: ${user?.name ?? "Desconocido"}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(width: AppDimensions.paddingS),
                Text('|', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(width: AppDimensions.paddingS),
                Text(
                  'ID: ${user?.id ?? "N/A"}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(width: AppDimensions.paddingM),
              ],
              BlocBuilder<ProductBloc, ProductState>(
                builder: (context, state) {
                  if (state is ProductLoaded) {
                    return Text(
                      '# Lista: ${state.currentPriceList}',
                      style: const TextStyle(fontSize: 14),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(width: AppDimensions.paddingM),
              DynamicDateTime(
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: constraints.maxWidth > 600 ? 14 : 12,
                    ),
              ),
            ],
          );
        },
      ),
      actions: [
        if (user != null)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                user!.tipo,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        Visibility(
          visible: user != null && user!.tipo == 'ADMIN',
          child: IconButton(
            iconSize: 18,
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await showDialog(
                context: context,
                builder: (context) => BlocProvider.value(
                  value: context.read<ClientsBloc>(),
                  child: const SettingsDialog(),
                ),
              );
            },
          ),
        ),
        IconButton(
          iconSize: 18,
          icon: const Icon(Icons.logout),
          onPressed: () {
            showLogoutDialog(context);
          },
        ),
        const SizedBox(width: AppDimensions.paddingS),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}