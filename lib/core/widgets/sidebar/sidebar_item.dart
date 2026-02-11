import 'package:flutter/material.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';

class SidebarItem extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback? onTap;
  final String? tooltip;
  final bool isHighlighted;

  const SidebarItem({
    super.key,
    required this.icon,
    this.isSelected = false,
    this.onTap,
    this.tooltip,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected || isHighlighted
        ? AppColors.sidebarAccent
        : AppColors.sidebarIconInactive;

    Widget iconWidget = Container(
      width: 48,
      height: 48,
      decoration: isHighlighted
          ? BoxDecoration(
              color: AppColors.sidebarAccent,
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      child: Icon(
        icon,
        color: isHighlighted ? Colors.white : color,
        size: 24,
      ),
    );

    if (tooltip != null) {
      iconWidget = Tooltip(
        message: tooltip!,
        child: iconWidget,
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: iconWidget,
      ),
    );
  }
}
