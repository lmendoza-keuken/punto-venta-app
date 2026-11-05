import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_onscreen_keyboard/flutter_onscreen_keyboard.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';

/// Ícono para abrir el teclado virtual in-app. Siempre visible en Windows.
class WindowsTouchKeyboardButton extends StatelessWidget {
  const WindowsTouchKeyboardButton({
    super.key,
    this.onPressed,
    this.color = AppColors.textSecondary,
    this.tooltip = 'Teclado en pantalla',
  });

  /// Si se provee, reemplaza el `open()` por defecto (p.ej. habilitar + focus).
  final VoidCallback? onPressed;
  final Color color;
  final String tooltip;

  static bool get isSupported => !kIsWeb && Platform.isWindows;

  @override
  Widget build(BuildContext context) {
    if (!isSupported) {
      return const SizedBox.shrink();
    }

    return IconButton(
      tooltip: tooltip,
      icon: Icon(Icons.keyboard_alt_outlined, color: color),
      onPressed: onPressed ??
          () {
            try {
              OnscreenKeyboard.of(context)
                ..moveToBottom()
                ..open();
            } catch (_) {
              // Sin OnscreenKeyboard en el árbol (p.ej. tests).
            }
          },
    );
  }
}
