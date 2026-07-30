import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../domain/entities/session.dart';

/// Result returned from [SessionForm] via the [onSubmit] callback.
class SessionFormResult {
  const SessionFormResult({
    required this.name,
    required this.description,
  });

  final String name;
  final String description;
}

/// Stateful form widget for creating or editing a session.
class SessionForm extends StatefulWidget {
  const SessionForm({
    this.initial,
    required this.onSubmit,
    super.key,
  });

  /// Existing session when editing; `null` when creating.
  final Session? initial;

  /// Called when the user submits a valid form. The parent is
  /// responsible for dispatching the matching bloc event.
  final ValueChanged<SessionFormResult> onSubmit;

  @override
  State<SessionForm> createState() => _SessionFormState();
}

class _SessionFormState extends State<SessionForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initial?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.initial?.description ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _submitting = true);
    try {
      widget.onSubmit(SessionFormResult(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
      ));
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: _nameController,
            label: l10n.sessionFieldName,
            hint: l10n.sessionFieldNameHint,
            textInputAction: TextInputAction.next,
            validator: (value) {
              final trimmed = (value ?? '').trim();
              if (trimmed.isEmpty) {
                return l10n.sessionFieldNameRequired;
              }
              if (trimmed.length < 2) {
                return l10n.sessionFieldNameTooShort;
              }
              if (trimmed.length > 60) {
                return l10n.sessionFieldNameTooLong;
              }
              return null;
            },
          ),
          const Gap(AppSpacing.lg),
          AppTextField(
            controller: _descriptionController,
            label: l10n.sessionFieldDescription,
            hint: l10n.sessionFieldDescriptionHint,
            maxLines: 3,
          ),
          const Spacer(),
          AppPrimaryButton(
            label: l10n.commonSave,
            onPressed: _submitting ? null : _submit,
            loading: _submitting,
          ),
        ],
      ),
    );
  }
}
