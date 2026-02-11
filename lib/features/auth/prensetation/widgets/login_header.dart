import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/core/constants/app_string.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingS),
      child: Column(
        children: [
          SvgPicture.asset(
            'assets/icons/logo.svg',
            width: 100,
            height: 100,
          ),
          const SizedBox(height: AppDimensions.paddingL),
          Text(
            AppStrings.appNameComplete,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppDimensions.paddingS),
          Text(
            'Inicia sesión con tu cuenta de Google',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
