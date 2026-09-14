import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_state.dart';

class QuantityField extends StatefulWidget {
  const QuantityField({super.key});

  @override
  State<QuantityField> createState() => _QuantityFieldState();
}

class _QuantityFieldState extends State<QuantityField> {
  final TextEditingController _quantityController =
      TextEditingController(text: '1');
  final FocusNode _quantityFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _quantityFocusNode.addListener(_selectAllOnFocus);
    context.read<UiBloc>().stream.listen((state) {
      if (state is UiLoaded && state.selectedQuantity == 1) {
        if (_quantityController.text != '1') {
          _quantityController.text = '1';
        }
      }
    });
  }

  void _selectAllOnFocus() {
    if (!_quantityFocusNode.hasFocus) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_quantityFocusNode.hasFocus) return;
      _quantityController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _quantityController.text.length,
      );
    });
  }

  @override
  void dispose() {
    _quantityFocusNode
      ..removeListener(_selectAllOnFocus)
      ..dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UiBloc, UiState>(
      builder: (context, state) {
        return Container(
          width: 80,
          height: 56,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(AppDimensions.borderRadiusM),
          ),
          child: Column(
            children: [
              const SizedBox(
                height: 20,
                child: Center(
                  child: Text(
                    'Cant.',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: TextFormField(
                  controller: _quantityController,
                  focusNode: _quantityFocusNode,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onTap: _selectAllOnFocus,
                  onChanged: (value) {
                    final quantity = int.tryParse(value) ?? 1;
                    if (quantity > 0) {
                      context.read<UiBloc>().add(SetQuantity(quantity));
                    } else {
                      _quantityController.text = '1';
                      context.read<UiBloc>().add(const SetQuantity(1));
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
