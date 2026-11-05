import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_onscreen_keyboard/flutter_onscreen_keyboard.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/core/constants/app_string.dart';
import 'package:punto_venta_app/core/services/windows_touch_input_service.dart';
import 'package:punto_venta_app/core/widgets/windows_touch_keyboard_button.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_state.dart';
import 'package:punto_venta_app/injection_container.dart';

class SearchField extends StatefulWidget {
  final TextEditingController controller;
  final bool autofocus;
  final Function(String) onSearchChanged;
  final VoidCallback onClearSearch;
  final Future<void> Function(String) onSubmitted;

  const SearchField({
    super.key,
    required this.controller,
    required this.autofocus,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onSubmitted,
  });

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  final FocusNode _focusNode = FocusNode();
  WindowsTouchInputService? _touchInput;

  /// Solo true tras el botón de teclado. Así el focus del scanner no abre el OSK.
  bool _oskEnabled = false;

  @override
  void initState() {
    super.initState();
    if (sl.isRegistered<WindowsTouchInputService>()) {
      _touchInput = sl<WindowsTouchInputService>();
    }
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus && _oskEnabled) {
      setState(() => _oskEnabled = false);
    }
  }

  void _requestFocus({bool retryAfterSnackBar = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNode.requestFocus();

      if (retryAfterSnackBar) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) _focusNode.requestFocus();
        });
      }
    });
  }

  Future<void> _handleSubmitted(String value, bool isBarcodeMode) async {
    await widget.onSubmitted(value);
    if (!mounted) return;
    if (isBarcodeMode) {
      _requestFocus(retryAfterSnackBar: true);
    }
  }

  /// Habilita el OSK y fuerza focus para que el package haga attach + open.
  void _openOnscreenKeyboard() {
    setState(() => _oskEnabled = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_focusNode.hasPrimaryFocus) {
        // Ya tiene focus: el listener del package no se re-dispara.
        _focusNode.unfocus();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _focusNode.requestFocus();
        });
      } else {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UiBloc, UiState>(
      listenWhen: (previous, current) {
        if (previous is UiLoaded && current is UiLoaded) {
          return previous.isBarcodeSearchEnabled !=
              current.isBarcodeSearchEnabled;
        }
        return false;
      },
      listener: (context, state) {
        if (state is UiLoaded && state.isBarcodeSearchEnabled) {
          _requestFocus();
        }
      },
      builder: (context, state) {
        final uiState = state as UiLoaded;
        final isBarcodeMode = uiState.isBarcodeSearchEnabled;

        return SizedBox(
          width: double.infinity,
          height: AppDimensions.buttonHeightm,
          child: OnscreenKeyboardTextField(
            controller: widget.controller,
            focusNode: _focusNode,
            // Solo abre el teclado in-app cuando el usuario tocó el botón.
            enableOnscreenKeyboard: _oskEnabled,
            autofocus: widget.autofocus || isBarcodeMode,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 0,
              ),
              hintText: isBarcodeMode
                  ? AppStrings.searchBarCodeHint
                  : AppStrings.searchHint,
              prefixIcon: isBarcodeMode
                  ? const SizedBox(
                      width: 48,
                      height: 48,
                      child: Center(
                        child: FaIcon(
                          FontAwesomeIcons.barcode,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.search,
                      color: AppColors.primary,
                    ),
              suffixIcon: _buildSuffixIcon(),
              suffixIconConstraints: const BoxConstraints(
                minWidth: 48,
                minHeight: 48,
              ),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppDimensions.borderRadiusM),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppDimensions.borderRadiusM),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppDimensions.borderRadiusM),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 2),
              ),
              filled: true,
            ),
            onChanged: isBarcodeMode ? null : widget.onSearchChanged,
            onSubmitted: (value) => _handleSubmitted(value, isBarcodeMode),
          ),
        );
      },
    );
  }

  Widget? _buildSuffixIcon() {
    final touchInput = _touchInput;
    final listenables = <Listenable>[widget.controller];
    if (touchInput != null) {
      listenables.add(touchInput);
    }

    return ListenableBuilder(
      listenable: Listenable.merge(listenables),
      builder: (context, _) {
        final showTouchKeyboard = touchInput?.isKeyboardAvailable ?? false;
        final hasText = widget.controller.text.isNotEmpty;
        if (!showTouchKeyboard && !hasText) {
          return const SizedBox.shrink();
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showTouchKeyboard)
              WindowsTouchKeyboardButton(onPressed: _openOnscreenKeyboard),
            if (hasText)
              IconButton(
                icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                onPressed: widget.onClearSearch,
              ),
          ],
        );
      },
    );
  }
}
