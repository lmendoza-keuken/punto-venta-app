import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/features/pos/domain/entities/product.dart';

Future<int?> showProductQuantityDialog(
  BuildContext context, {
  required Product product,
  int initialQuantity = 0,
  bool isDeleteMode = false,
}) {
  return showDialog<int>(
    context: context,
    barrierDismissible: false,
    builder: (_) => ProductQuantityDialog(
      product: product,
      initialQuantity: initialQuantity.clamp(0, 999),
      isDeleteMode: isDeleteMode,
    ),
  );
}

class ProductQuantityDialog extends StatefulWidget {
  final Product product;
  final int initialQuantity;
  final bool isDeleteMode;

  const ProductQuantityDialog({
    super.key,
    required this.product,
    this.initialQuantity = 1,
    this.isDeleteMode = false,
  });

  @override
  State<ProductQuantityDialog> createState() => _ProductQuantityDialogState();
}

class _ProductQuantityDialogState extends State<ProductQuantityDialog> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  static const int _maxQuantity = 999;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.initialQuantity}');
    _focusNode = FocusNode()..addListener(_selectAllOnFocus);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_selectAllOnFocus)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  void _selectAllOnFocus() {
    if (!_focusNode.hasFocus) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_focusNode.hasFocus) return;
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    });
  }

  int get _quantity {
    final parsed = int.tryParse(_controller.text.trim());
    if (parsed == null || parsed < 0) return 0;
    return parsed.clamp(0, _maxQuantity);
  }

  void _setQuantity(int value) {
    final next = value.clamp(0, _maxQuantity);
    setState(() {
      _controller.text = '$next';
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    });
  }

  void _increment() => _setQuantity(_quantity + 1);

  void _decrement() {
    if (_quantity <= 0) return;
    _setQuantity(_quantity - 1);
  }

  void _removeAll() {
    Navigator.of(context).pop(0);
  }

  void _submit() {
    Navigator.of(context).pop(_quantity);
  }

  @override
  Widget build(BuildContext context) {
    final qty = _quantity;
    final canRemoveAll = widget.initialQuantity > 0 || qty > 0;
    final actionColor =
        widget.isDeleteMode ? AppColors.error : AppColors.primary;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusM),
      ),
      title: Row(
        children: [
          Icon(
            widget.isDeleteMode ? Icons.remove_shopping_cart : Icons.numbers,
            color: actionColor,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Cantidad en carrito',
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.product.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'Código: ${widget.product.id}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingL),
            Row(
              children: [
                _RoundActionButton(
                  icon: Icons.remove,
                  color: AppColors.primary,
                  onPressed: qty > 0 ? _decrement : null,
                ),
                const SizedBox(width: AppDimensions.paddingS),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.primary.withValues(alpha: 0.06),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingM,
                        vertical: AppDimensions.paddingM,
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
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    onTap: _selectAllOnFocus,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _submit(),
                  ),
                ),
                const SizedBox(width: AppDimensions.paddingS),
                _RoundActionButton(
                  icon: Icons.add,
                  color: AppColors.primary,
                  onPressed: qty < _maxQuantity ? _increment : null,
                ),
                const SizedBox(width: AppDimensions.paddingS),
                _RoundActionButton(
                  icon: Icons.delete_outline,
                  color: AppColors.error,
                  onPressed: canRemoveAll ? _removeAll : null,
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: actionColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}

class _RoundActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  const _RoundActionButton({
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Material(
      color: enabled
          ? color.withValues(alpha: 0.12)
          : AppColors.textHint.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            icon,
            color: enabled ? color : AppColors.textHint,
          ),
        ),
      ),
    );
  }
}
