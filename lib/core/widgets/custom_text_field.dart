import 'package:flutter/material.dart';
import 'package:flutter_onscreen_keyboard/flutter_onscreen_keyboard.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/core/widgets/windows_touch_keyboard_button.dart';

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

  /// Si true (default), en Windows usa el teclado virtual in-app.
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

  bool get _useOnscreenKeyboard =>
      showTouchKeyboardButton && WindowsTouchKeyboardButton.isSupported;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppDimensions.paddingS),
        if (_useOnscreenKeyboard)
          OnscreenKeyboardTextFormField(
            controller: controller,
            obscureText: obscureText,
            validator: validator,
            enableOnscreenKeyboard: true,
            onTap: onTap,
            readOnly: readOnly,
            decoration: InputDecoration(
              hintText: hint ?? label,
              prefixIcon: prefixIcon,
              suffixIcon: _buildSuffixIcon(),
              suffixIconConstraints: const BoxConstraints(
                minWidth: 48,
                minHeight: 48,
              ),
            ),
          )
        else
          TextFormField(
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
          ),
      ],
    );
  }

  Widget? _buildSuffixIcon() {
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
