import 'package:flutter/material.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/dialogs/cash_register/open_cash_register_dialog.dart';

class ClosedRegisterView extends StatelessWidget {
  const ClosedRegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    final compact = LayoutSpec.of(context).isCompact;
    final padding = compact ? 20.0 : 32.0;
    final iconSize = compact ? 56.0 : 80.0;
    final titleSize = compact ? 20.0 : 24.0;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(compact ? 12 : 24),
        child: Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                spreadRadius: 5,
                blurRadius: 15,
              ),
            ],
          ),
          constraints: const BoxConstraints(
            maxWidth: 500,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(compact ? 16.0 : 24.0),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_outline,
                  size: iconSize,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: compact ? 16 : 24),
              Text(
                'Caja Cerrada',
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Para comenzar a facturar y registrar movimientos, por favor abre la caja.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: compact ? 20 : 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text(
                    'Abrir Caja',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  onPressed: () {
                    showOpenCashRegisterDialog(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
