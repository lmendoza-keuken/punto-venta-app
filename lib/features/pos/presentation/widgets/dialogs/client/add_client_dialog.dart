import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/features/pos/domain/entities/client.dart';
import 'package:uuid/uuid.dart';
import '../../../../../../core/constants/app_dimensions.dart';
import '../../../../../../core/widgets/custom_text_field.dart';
import '../../../bloc/clients/clients_bloc.dart';
import '../../../bloc/clients/clients_event.dart';

class AddClientDialog extends StatefulWidget {
  const AddClientDialog({super.key});

  @override
  State<AddClientDialog> createState() => _AddClientDialogState();
}

class _AddClientDialogState extends State<AddClientDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _docCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _docCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final id = const Uuid().v4();

    final client = Client(
      id: id,
      name: _nameCtrl.text.trim(),
      document: _docCtrl.text.trim().isEmpty ? null : _docCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      email: null,
      address:
          _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
    );

    context.read<ClientsBloc>().add(AddClientEvent(client));
    Navigator.of(context).pop(client);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetAnimationDuration: Duration.zero,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20.0)),
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          automaticallyImplyLeading: true,
          title: const Text('Agregar Cliente'),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CustomTextField(
                      label: 'Nombre',
                      controller: _nameCtrl,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'Nombre requerido';
                        return null;
                      }),
                  const SizedBox(height: AppDimensions.paddingS),
                  CustomTextField(
                      label: 'Documento (opcional)', controller: _docCtrl),
                  const SizedBox(height: AppDimensions.paddingS),
                  CustomTextField(
                      label: 'Teléfono (opcional)', controller: _phoneCtrl),
                  const SizedBox(height: AppDimensions.paddingS),
                  CustomTextField(
                      label: 'Dirección (opcional)', controller: _addressCtrl),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: AppDimensions.buttonHeightS,
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancelar'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SizedBox(
                          height: AppDimensions.buttonHeightS,
                          child: ElevatedButton(
                            onPressed: _save,
                            child: const Text('Guardar'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
