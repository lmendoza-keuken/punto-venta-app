import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/core/constants/app_string.dart';
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

  /// false → foco programático / scanner, sin soft keyboard.
  /// true → el usuario tocó el input → soft keyboard.
  bool _keyboardFromUserTap = false;
  bool _openingKeyboard = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusForScanner();
    });
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      if (_keyboardFromUserTap && mounted) {
        setState(() => _keyboardFromUserTap = false);
      } else {
        _keyboardFromUserTap = false;
      }
      return;
    }
    if (!_keyboardFromUserTap) {
      _hideSoftKeyboard();
    }
  }

  void _hideSoftKeyboard() {
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  void _showSoftKeyboard() {
    SystemChannels.textInput.invokeMethod('TextInput.show');
  }

  TextInputType _keyboardTypeFor({
    required bool isBarcodeMode,
    required bool fromUserTap,
  }) {
    if (!fromUserTap) return TextInputType.none;
    // Misma configuración que QuantityField en barcode.
    if (isBarcodeMode) return TextInputType.number;
    return TextInputType.text;
  }

  void _focusForScanner({bool retryAfterSnackBar = false}) {
    void apply() {
      if (!mounted) return;
      setState(() => _keyboardFromUserTap = false);
      _focusNode.requestFocus();
      _hideSoftKeyboard();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      apply();
      if (retryAfterSnackBar) {
        Future.delayed(const Duration(milliseconds: 100), apply);
      }
    });
  }

  Future<void> _onUserTap() async {
    if (_keyboardFromUserTap) {
      _showSoftKeyboard();
      return;
    }
    if (_openingKeyboard) return;
    _openingKeyboard = true;

    try {
      // 1) Soltar conexión none.
      _focusNode.unfocus();
      _hideSoftKeyboard();
      await Future<void>.delayed(Duration.zero);
      if (!mounted) return;

      // 2) Rebuild con number/text + Key nuevo (recrea EditableText/IME).
      setState(() => _keyboardFromUserTap = true);
      await Future<void>.delayed(Duration.zero);
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || !_keyboardFromUserTap) return;

      // 3) Enfocar con el nuevo keyboardType y mostrar IME.
      _focusNode.requestFocus();
      _showSoftKeyboard();
    } finally {
      _openingKeyboard = false;
    }
  }

  Future<void> _handleSubmitted(String value) async {
    await widget.onSubmitted(value);
    if (!mounted) return;
    _focusForScanner(retryAfterSnackBar: true);
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
        if (state is UiLoaded) {
          _focusForScanner();
        }
      },
      builder: (context, state) {
        final uiState = state as UiLoaded;
        final isBarcodeMode = uiState.isBarcodeSearchEnabled;
        final keyboardType = _keyboardTypeFor(
          isBarcodeMode: isBarcodeMode,
          fromUserTap: _keyboardFromUserTap,
        );

        return SizedBox(
          width: double.infinity,
          height: AppDimensions.buttonHeightm,
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (_) {
              if (!_keyboardFromUserTap) {
                _onUserTap();
              }
            },
            child: TextField(
              // Key fuerza remount al cambiar none ↔ number/text (IME Android).
              key: ValueKey(
                'search-kb-${_keyboardFromUserTap ? (isBarcodeMode ? 'num' : 'text') : 'none'}',
              ),
              controller: widget.controller,
              focusNode: _focusNode,
              autofocus: false,
              keyboardType: keyboardType,
              textInputAction: TextInputAction.done,
              inputFormatters: isBarcodeMode && _keyboardFromUserTap
                  ? <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ]
                  : null,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 0,
                ),
                hintText: isBarcodeMode
                    ? AppStrings.searchBarCodeHint
                    : AppStrings.searchHint,
                prefixIcon: IconButton(
                  tooltip: 'Abrir teclado',
                  onPressed: _onUserTap,
                  icon: isBarcodeMode
                      ? const FaIcon(
                          FontAwesomeIcons.barcode,
                          color: AppColors.primary,
                          size: 22,
                        )
                      : const Icon(
                          Icons.search,
                          color: AppColors.primary,
                        ),
                ),
                suffixIcon: widget.controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: AppColors.textSecondary),
                        onPressed: widget.onClearSearch,
                      )
                    : null,
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
              onSubmitted: _handleSubmitted,
            ),
          ),
        );
      },
    );
  }
}
