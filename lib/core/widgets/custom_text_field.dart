import 'package:flutter/material.dart';
import 'package:flutter_onscreen_keyboard/flutter_onscreen_keyboard.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/core/services/windows_touch_input_service.dart';
import 'package:punto_venta_app/core/widgets/windows_touch_keyboard_button.dart';
import 'package:punto_venta_app/injection_container.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final bool obscureText;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType keyboardType;
  final VoidCallback? onTap;
  final bool readOnly;

  /// Si true (default), en Windows touch usa el teclado virtual in-app.
  final bool showTouchKeyboardButton;

  const CustomTextField({
    super.key,
    required this.label,
    this.hint,
    required this.controller,
    this.obscureText = false,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.onTap,
    this.readOnly = false,
    this.showTouchKeyboardButton = true,
  });

  bool get _useOnscreenKeyboard {
    if (!showTouchKeyboardButton) return false;
    if (!sl.isRegistered<WindowsTouchInputService>()) return false;
    return sl<WindowsTouchInputService>().isKeyboardAvailable;
  }

  @override
  Widget build(BuildContext context) {
    final touchInput = sl.isRegistered<WindowsTouchInputService>()
        ? sl<WindowsTouchInputService>()
        : null;

    Widget field({required bool enableOsk}) {
      if (enableOsk) {
        return OnscreenKeyboardTextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          // En forms de diálogo, abrir al focus está bien (no es el scanner).
          enableOnscreenKeyboard: true,
          onTap: onTap,
          readOnly: readOnly,
          decoration: InputDecoration(
            hintText: hint ?? label,
            prefixIcon: prefixIcon,
            suffixIcon: _buildSuffixIcon(enableOsk: true),
            suffixIconConstraints: const BoxConstraints(
              minWidth: 48,
              minHeight: 48,
            ),
          ),
        );
      }

      return TextFormField(
        controller: controller,
        obscureText: obscureText,
        validator: validator,
        keyboardType: keyboardType,
        onTap: onTap,
        readOnly: readOnly,
        decoration: InputDecoration(
          hintText: hint ?? label,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
        ),
      );
    }

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppDimensions.paddingS),
        if (touchInput == null)
          field(enableOsk: false)
        else
          ListenableBuilder(
            listenable: touchInput,
            builder: (context, _) => field(enableOsk: _useOnscreenKeyboard),
          ),
      ],
    );

    return content;
  }

  Widget? _buildSuffixIcon({required bool enableOsk}) {
    if (!enableOsk && suffixIcon == null) return null;
    if (!enableOsk) return suffixIcon;

    if (suffixIcon == null) {
      return const WindowsTouchKeyboardButton();
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const WindowsTouchKeyboardButton(),
        suffixIcon!,
      ],
    );
  }
}
