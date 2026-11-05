import 'package:flutter/material.dart';
import 'package:flutter_onscreen_keyboard/flutter_onscreen_keyboard.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/services/windows_touch_input_service.dart';
import 'package:punto_venta_app/injection_container.dart';

/// Ícono para abrir el teclado virtual in-app.
/// Visible si el primario es touch o si se forzó en Configuración.
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

  @override
  Widget build(BuildContext context) {
    if (!sl.isRegistered<WindowsTouchInputService>()) {
      return const SizedBox.shrink();
    }

    final service = sl<WindowsTouchInputService>();
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        if (!service.isKeyboardAvailable) {
          return const SizedBox.shrink();
        }
        return IconButton(
          tooltip: tooltip,
          icon: Icon(Icons.keyboard_alt_outlined, color: color),
          onPressed: onPressed ??
              () {
                try {
                  OnscreenKeyboard.of(context).open();
                } catch (_) {
                  // Sin OnscreenKeyboard en el árbol (p.ej. tests).
                }
              },
        );
      },
    );
  }
}
