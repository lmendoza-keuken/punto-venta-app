import 'package:flutter/material.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';

class ResponsiveTwoColumn extends StatelessWidget {
  final Widget left;
  final Widget right;
  final double wideBreakpoint;
  final double mediumBreakpoint;

  const ResponsiveTwoColumn({
    super.key,
    required this.left,
    required this.right,
    this.wideBreakpoint = 1200,
    this.mediumBreakpoint = 800,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final maxWidth = constraints.maxWidth;

      if (maxWidth > wideBreakpoint) {
        return Row(
          children: [
            Expanded(flex: 2, child: left),
            SizedBox(
              width: AppDimensions.cartPanelWidth * 1.5,
              child: right,
            ),
          ],
        );
      } else if (maxWidth > mediumBreakpoint) {
        return Row(
          children: [
            Expanded(flex: 2, child: left),
            SizedBox(
              width: AppDimensions.cartPanelWidth * 0.85,
              child: right,
            ),
          ],
        );
      } else {
        return Column(
          children: [
            Expanded(flex: 2, child: left),
            SizedBox(
              height: 200,
              child: right,
            ),
          ],
        );
      }
    });
  }
}