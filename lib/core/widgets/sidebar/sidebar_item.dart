import 'package:flutter/material.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';

class SidebarItem extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback? onTap;
  final String? tooltip;
  final bool isHighlighted;
  final bool? isDisabled;
  final bool showLabel;

  const SidebarItem({
    super.key,
    required this.icon,
    this.isSelected = false,
    this.onTap,
    this.tooltip,
    this.isHighlighted = false,
    this.isDisabled = false,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected || isHighlighted
        ? AppColors.sidebarAccent
        : AppColors.sidebarIconInactive;
    final iconColor = isDisabled == true
        ? AppColors.sidebarIconDisabled
        : isHighlighted
            ? Colors.white
            : color;

    final iconBox = Container(
      width: 48,
      height: 48,
      decoration: isHighlighted
          ? BoxDecoration(
              color: AppColors.sidebarAccent,
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      child: Icon(icon, color: iconColor, size: 24),
    );

    Widget content;
    if (showLabel && tooltip != null) {
      content = Row(
        children: [
          iconBox,
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tooltip!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight:
                    isHighlighted ? FontWeight.w600 : FontWeight.w500,
                color: isDisabled == true
                    ? AppColors.sidebarIconDisabled
                    : Colors.black87,
              ),
            ),
          ),
        ],
      );
    } else {
      content = tooltip != null
          ? Tooltip(message: tooltip!, child: iconBox)
          : iconBox;
    }

    return InkWell(
      onTap: isDisabled == true ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: 4,
          horizontal: showLabel ? 8 : 0,
        ),
        child: content,
      ),
    );
  }
}
