import 'package:flutter/material.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';

/// Caps a preferred dialog width to the current viewport.
class ResponsiveDialogWidth extends StatelessWidget {
  final double preferredWidth;
  final double? height;
  final Widget child;

  const ResponsiveDialogWidth({
    super.key,
    required this.preferredWidth,
    required this.child,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppDimensions.dialogWidth(context, preferredWidth),
      height: height,
      child: child,
    );
  }
}
