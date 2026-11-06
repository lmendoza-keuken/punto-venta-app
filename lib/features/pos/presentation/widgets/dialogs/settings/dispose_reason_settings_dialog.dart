import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/widgets/responsive_dialog_width.dart';
import 'package:punto_venta_app/features/pos/domain/entities/dispose_reason.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/create_dispose_reason_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/delete_dispose_reason_usecase.dart';
import 'package:punto_venta_app/features/pos/domain/usecases/fetch_dispose_reasons_usecase.dart';
import 'package:punto_venta_app/injection_container.dart' as di;

Future<void> showDisposeReasonSettingsDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const DisposeReasonSettingsDialog(),
  );
}

class DisposeReasonSettingsDialog extends StatefulWidget {
  const DisposeReasonSettingsDialog({super.key});

  @override
  State<DisposeReasonSettingsDialog> createState() =>
      _DisposeReasonSettingsDialogState();
}

class _DisposeReasonSettingsDialogState
    extends State<DisposeReasonSettingsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();

  List<DisposeReason> _reasons = [];
  bool _isLoading = true;
  bool _isSaving = false;
  int? _deletingId;
  String? _errorMessage;
  bool _showCreateForm = false;

  @override
  void initState() {
    super.initState();
    _loadReasons();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadReasons() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final reasons = await di.sl<FetchDisposeReasonsUsecase>()();
      if (!mounted) return;
      setState(() {
        _reasons = reasons;
        _isLoading = false;
        _showCreateForm = reasons.isEmpty;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final created = await di.sl<CreateDisposeReasonUsecase>()(
        code: _codeController.text.trim().toUpperCase(),
        description: _descriptionController.text.trim(),
      );
      if (!mounted) return;
      _codeController.clear();
      _descriptionController.clear();
      setState(() {
        _reasons = [..._reasons, created];
        _isSaving = false;
        _showCreateForm = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _confirmDelete(DisposeReason reason) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar motivo'),
        content: Text(
          '¿Eliminar el motivo "${reason.description}"'
          '${reason.code != null ? ' (${reason.code})' : ''}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await _delete(reason.id);
  }

  Future<void> _delete(int reasonId) async {
    setState(() {
      _deletingId = reasonId;
      _errorMessage = null;
    });

    try {
      await di.sl<DeleteDisposeReasonUsecase>()(reasonId);
      if (!mounted) return;
      setState(() {
        _reasons = _reasons.where((r) => r.id != reasonId).toList();
        _deletingId = null;
        if (_reasons.isEmpty) _showCreateForm = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _deletingId = null;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Widget _buildCreateForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _codeController,
            enabled: !_isSaving,
            textCapitalization: TextCapitalization.characters,
            maxLength: 3,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
              LengthLimitingTextInputFormatter(3),
              TextInputFormatter.withFunction((oldValue, newValue) {
                return newValue.copyWith(text: newValue.text.toUpperCase());
              }),
            ],
            decoration: const InputDecoration(
              labelText: 'Código',
              hintText: 'Ej: VEN',
              border: OutlineInputBorder(),
              counterText: '',
            ),
            validator: (value) {
              final code = value?.trim() ?? '';
              if (code.isEmpty) return 'Código requerido';
              if (code.length > 3) return 'Máximo 3 caracteres';
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descriptionController,
            enabled: !_isSaving,
            textCapitalization: TextCapitalization.sentences,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Descripción',
              hintText: 'Ej: Mercadería vencida',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Descripción requerida';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (_reasons.isNotEmpty)
                TextButton(
                  onPressed: _isSaving
                      ? null
                      : () => setState(() => _showCreateForm = false),
                  child: const Text('Cancelar'),
                ),
              const Spacer(),
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Guardar'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReasonsList() {
    if (_reasons.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'No hay motivos configurados. Creá el primero.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 280),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: _reasons.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final reason = _reasons[index];
          final isDeleting = _deletingId == reason.id;
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: Colors.brown.withValues(alpha: 0.12),
              foregroundColor: Colors.brown.shade700,
              child: Text(
                (reason.code ?? '?').toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(reason.description),
            subtitle: reason.code != null ? Text('Código: ${reason.code}') : null,
            trailing: isDeleting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    tooltip: 'Eliminar',
                    icon: const Icon(Icons.delete_outline, color: AppColors.error),
                    onPressed: _deletingId != null || _isSaving
                        ? null
                        : () => _confirmDelete(reason),
                  ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Motivos de mal estado'),
      content: ResponsiveDialogWidth(
        preferredWidth: 460,
        child: _isLoading
            ? const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!_showCreateForm) ...[
                    _buildReasonsList(),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _deletingId != null
                            ? null
                            : () => setState(() => _showCreateForm = true),
                        icon: const Icon(Icons.add),
                        label: const Text('Nuevo motivo'),
                      ),
                    ),
                  ] else ...[
                    if (_reasons.isNotEmpty) ...[
                      Text(
                        'Alta de motivo',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                    ],
                    _buildCreateForm(),
                  ],
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving || _deletingId != null
              ? null
              : () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}
