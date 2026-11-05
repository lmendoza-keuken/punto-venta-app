import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_onscreen_keyboard/flutter_onscreen_keyboard.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/core/constants/app_string.dart';
import 'package:punto_venta_app/core/widgets/windows_touch_keyboard_button.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_state.dart';

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

  /// Solo true tras el botón de teclado. Así el focus del scanner no abre el OSK.
  bool _oskEnabled = false;

  /// Evita que el unfocus del reopen apague `_oskEnabled` a mitad del ciclo.
  bool _suppressOskDisable = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_suppressOskDisable) return;
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

  /// Habilita el OSK, adjunta el campo y abre abajo (también tras haber cerrado).
  Future<void> _openOnscreenKeyboard() async {
    _suppressOskDisable = true;
    setState(() => _oskEnabled = true);

    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;

    // Si ya tenía focus (p.ej. tras cerrar el teclado), forzar re-attach.
    if (_focusNode.hasPrimaryFocus) {
      _focusNode.unfocus();
      await Future<void>.delayed(Duration.zero);
      if (!mounted) return;
    }

    _focusNode.requestFocus();
    await Future<void>.delayed(const Duration(milliseconds: 32));
    if (!mounted) return;

    try {
      OnscreenKeyboard.of(context)
        ..moveToBottom()
        ..open();
    } catch (_) {}

    _suppressOskDisable = false;
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
        final showKeyboardButton = WindowsTouchKeyboardButton.isSupported;

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
              suffixIcon: _buildSuffixIcon(showKeyboardButton),
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

  Widget? _buildSuffixIcon(bool showKeyboardButton) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final hasText = widget.controller.text.isNotEmpty;
        if (!showKeyboardButton && !hasText) {
          return const SizedBox.shrink();
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showKeyboardButton)
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
