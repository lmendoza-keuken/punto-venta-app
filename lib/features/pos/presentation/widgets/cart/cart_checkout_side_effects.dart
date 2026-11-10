import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/utils/confirm_sale_flow_logger.dart';
import 'package:punto_venta_app/features/app_update/presentation/widgets/update_available_dialog.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/checkout/checkout_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/checkout/checkout_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/checkout/checkout_state.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/clients/clients_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/clients/clients_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/printer/printer_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/printer/printer_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/printer/printer_state.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_state.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/common/error_dialog.dart';

/// Shared checkout/printer side-effects used by expanded CartPanel and compact shell.
class CartCheckoutSideEffects extends StatelessWidget {
  final Widget child;

  const CartCheckoutSideEffects({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<CheckoutBloc, CheckoutState>(
          listener: (context, checkoutState) {
            if (checkoutState is CheckoutSuccess) {
              final uiState = context.read<UiBloc>().state;
              final cartMode =
                  uiState is UiLoaded ? uiState.cartMode : CartMode.sale;
              final pendingUpdate = checkoutState.pendingUpdate;

              ConfirmSaleFlowLog.step(
                'checkout_success_side_effect',
                detail:
                    'cartMode=$cartMode ticketId=${checkoutState.printJob.ticketId}',
              );

              if (cartMode != CartMode.returnMode) {
                ConfirmSaleFlowLog.step(
                  'dispatch_print_ticket',
                  detail:
                      'ticketId=${checkoutState.printJob.ticketId} '
                      'template=${checkoutState.printJob.templateType}',
                );
                context.read<PrinterBloc>().add(PrintTicket(
                      printJob: checkoutState.printJob,
                    ));
              } else {
                ConfirmSaleFlowLog.end(
                  'success_no_print',
                  detail: 'cartMode=returnMode',
                );
              }

              context.read<CartBloc>().add(ClearCart());
              context.read<CheckoutBloc>().add(const ResetCheckout());
              context.read<ClientsBloc>().add(ResetToDefaultClientEvent());

              if (cartMode != CartMode.sale) {
                context.read<UiBloc>().add(const SetCartMode(CartMode.sale));
              }
              context.read<UiBloc>().add(CloseConfirmationPanel());

              if (cartMode == CartMode.sale &&
                  pendingUpdate != null &&
                  pendingUpdate.updateAvailable &&
                  pendingUpdate.release != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!context.mounted) return;
                  showUpdateAvailableDialog(
                    context: context,
                    release: pendingUpdate.release!,
                    currentVersion: pendingUpdate.currentVersion,
                  );
                });
              }
            } else if (checkoutState is CheckoutError) {
              ConfirmSaleFlowLog.fail(
                'checkout_error_ui',
                checkoutState.message,
              );
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext dialogContext) {
                  return ErrorDialog(
                    message: checkoutState.message,
                    onAccept: () {
                      context.read<CheckoutBloc>().add(const ResetCheckout());
                    },
                  );
                },
              );
            }
          },
        ),
        BlocListener<PrinterBloc, PrinterState>(
          listener: (context, printerState) {
            if (printerState is PrinterSuccess) {
              ConfirmSaleFlowLog.end(
                'print_success',
                detail: printerState.message,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(printerState.message),
                  backgroundColor: AppColors.success,
                ),
              );
            } else if (printerState is PrinterError) {
              ConfirmSaleFlowLog.fail('print_error', printerState.message);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(printerState.message),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
        ),
      ],
      child: child,
    );
  }
}
