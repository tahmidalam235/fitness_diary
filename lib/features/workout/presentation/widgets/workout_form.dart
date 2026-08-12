import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../domain/entities/body_part.dart';
import '../../domain/entities/workout.dart';
import 'body_part_picker_sheet.dart';

/// Result returned from [WorkoutForm] via the [onSubmit] callback.
class WorkoutFormResult {
  const WorkoutFormResult({
    required this.exerciseName,
    required this.defaultSets,
    required this.defaultReps,
    this.defaultDurationSeconds,
    this.defaultWeight,
    this.notes = '',
    this.targetedBodyPart,
  });

  final String exerciseName;
  final int defaultSets;
  final int defaultReps;
  final int? defaultDurationSeconds;
  final double? defaultWeight;
  final String notes;
  final BodyPart? targetedBodyPart;
}

/// Stateful form for creating or editing a workout.
class WorkoutForm extends StatefulWidget {
  const WorkoutForm({this.initial, required this.onSubmit, super.key});

  final Workout? initial;
  final ValueChanged<WorkoutFormResult> onSubmit;

  @override
  State<WorkoutForm> createState() => _WorkoutFormState();
}

class _WorkoutFormState extends State<WorkoutForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _setsController;
  late final TextEditingController _repsController;
  late final TextEditingController _durationController;
  late final TextEditingController _weightController;
  late final TextEditingController _notesController;

  BodyPart? _selectedBodyPart;

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _nameController = TextEditingController(text: initial?.exerciseName ?? '');
    _setsController = TextEditingController(
      text: (initial?.defaultSets ?? 3).toString(),
    );
    _repsController = TextEditingController(
      text: (initial?.defaultReps ?? 10).toString(),
    );
    // Duration is entered in minutes in the UI but stored as
    // `defaultDurationSeconds` on the entity (DB / bloc / repo are
    // untouched). Convert seconds → minutes for the initial value.
    _durationController = TextEditingController(
      text: initial == null || initial.defaultDurationSeconds == null
          ? ''
          : (initial.defaultDurationSeconds! ~/ 60).toString(),
    );
    _weightController = TextEditingController(
      text: initial?.defaultWeight?.toString() ?? '',
    );
    _notesController = TextEditingController(text: initial?.notes ?? '');
    _selectedBodyPart = initial?.targetedBodyPart;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _durationController.dispose();
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _submitting = true);
    try {
      // Duration is entered in minutes in the UI; convert to seconds for
      // the entity (whose `defaultDurationSeconds` field is the source
      // of truth everywhere else in the app).
      final durationMinutesRaw = _durationController.text.trim();
      final duration = durationMinutesRaw.isEmpty
          ? null
          : (int.tryParse(durationMinutesRaw) == null
                ? null
                : int.parse(durationMinutesRaw) * 60);
      final weight = _weightController.text.trim().isEmpty
          ? null
          : double.tryParse(_weightController.text.trim());
      widget.onSubmit(
        WorkoutFormResult(
          exerciseName: _nameController.text.trim(),
          defaultSets: int.parse(_setsController.text.trim()),
          defaultReps: int.parse(_repsController.text.trim()),
          defaultDurationSeconds: duration,
          defaultWeight: weight,
          notes: _notesController.text.trim(),
          targetedBodyPart: _selectedBodyPart,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  String? _validatePositiveInt(
    String? value, {
    required int min,
    required int max,
    required AppLocalizations l10n,
  }) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) {
      return l10n.workoutFieldNumberRequired;
    }
    final parsed = int.tryParse(trimmed);
    if (parsed == null) {
      return l10n.workoutFieldNumberRequired;
    }
    if (parsed < min) {
      return l10n.workoutFieldNumberTooSmall(min);
    }
    if (parsed > max) {
      return l10n.workoutFieldNumberTooLarge(max);
    }
    return null;
  }

  String? _validateOptionalPositiveInt(
    String? value, {
    required int max,
    required AppLocalizations l10n,
  }) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) return null;
    final parsed = int.tryParse(trimmed);
    if (parsed == null) {
      return l10n.workoutFieldNumberRequired;
    }
    if (parsed < 0 || parsed > max) {
      return l10n.workoutFieldNumberTooLarge(max);
    }
    return null;
  }

  String? _validateOptionalPositiveDouble(
    String? value, {
    required double max,
    required AppLocalizations l10n,
  }) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) return null;
    final parsed = double.tryParse(trimmed);
    if (parsed == null) {
      return l10n.workoutFieldNumberRequired;
    }
    if (parsed < 0 || parsed > max) {
      return l10n.workoutFieldNumberTooLarge(max.toInt());
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          // Section: identity
          _SectionLabel(
            label: 'Identity'.toUpperCase(),
            color: theme.colorScheme.primary,
          ),
          const Gap(AppSpacing.sm),
          AppTextField(
            controller: _nameController,
            label: l10n.workoutFieldName,
            hint: l10n.workoutFieldNameHint,
            prefixIcon: Icons.fitness_center_rounded,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            validator: (value) {
              final trimmed = (value ?? '').trim();
              if (trimmed.isEmpty) {
                return l10n.workoutFieldNameRequired;
              }
              if (trimmed.length < 2) {
                return l10n.workoutFieldNameTooShort;
              }
              return null;
            },
          ),
          const Gap(AppSpacing.xl),

          // Section: target
          _SectionLabel(
            label: 'Target'.toUpperCase(),
            color: theme.colorScheme.primary,
          ),
          const Gap(AppSpacing.sm),
          _BodyPartField(
            value: _selectedBodyPart,
            onChanged: (part) => setState(() => _selectedBodyPart = part),
          ),
          const Gap(AppSpacing.xl),

          // Section: defaults
          _SectionLabel(
            label: 'Defaults'.toUpperCase(),
            color: theme.colorScheme.primary,
          ),
          const Gap(AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _setsController,
                  label: l10n.workoutFieldDefaultSets,
                  hint: '3',
                  prefixIcon: Icons.format_list_numbered_rounded,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      _validatePositiveInt(v, min: 1, max: 50, l10n: l10n),
                ),
              ),
              const Gap(AppSpacing.md),
              Expanded(
                child: AppTextField(
                  controller: _repsController,
                  label: l10n.workoutFieldDefaultReps,
                  hint: '10',
                  prefixIcon: Icons.repeat_rounded,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      _validatePositiveInt(v, min: 1, max: 1000, l10n: l10n),
                ),
              ),
            ],
          ),
          const Gap(AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _durationController,
                  label: l10n.workoutFieldDefaultDuration,
                  hint: 'Optional',
                  prefixIcon: Icons.schedule_rounded,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textInputAction: TextInputAction.next,
                  validator: (v) => _validateOptionalPositiveInt(
                    v,
                    // 24 hours in minutes — the field is entered in
                    // minutes and converted to seconds before save.
                    max: 24 * 60,
                    l10n: l10n,
                  ),
                ),
              ),
              const Gap(AppSpacing.md),
              Expanded(
                child: AppTextField(
                  controller: _weightController,
                  label: l10n.workoutFieldDefaultWeight,
                  hint: 'Optional',
                  prefixIcon: Icons.monitor_weight_rounded,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.newline,
                  validator: (v) => _validateOptionalPositiveDouble(
                    v,
                    max: 100000,
                    l10n: l10n,
                  ),
                ),
              ),
            ],
          ),
          const Gap(AppSpacing.xl),

          // Section: notes
          _SectionLabel(
            label: 'Notes'.toUpperCase(),
            color: theme.colorScheme.primary,
          ),
          const Gap(AppSpacing.sm),
          AppTextField(
            controller: _notesController,
            label: l10n.workoutFieldNotes,
            hint: 'Coaching cues, tempo, rest cues…',
            prefixIcon: Icons.notes_rounded,
            maxLines: 3,
            textInputAction: TextInputAction.newline,
          ),
          const Gap(AppSpacing.xl),

          // Save CTA — premium gradient button.
          SizedBox(
            height: 56,
            child: FilledButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(
                _submitting ? 'Saving…' : l10n.commonSave,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  fontSize: 16,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                elevation: 2,
                shadowColor: theme.colorScheme.primary.withValues(alpha: 0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          const Gap(AppSpacing.sm),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tappable card that opens the [BodyPartPickerSheet] and reflects the
/// current selection (icon + label) or a placeholder when nothing is
/// picked.
class _BodyPartField extends StatelessWidget {
  const _BodyPartField({required this.value, required this.onChanged});

  final BodyPart? value;
  final ValueChanged<BodyPart?> onChanged;

  Future<void> _open(BuildContext context) async {
    final picked = await BodyPartPickerSheet.show(
      context,
      initial: value,
    );
    if (picked != null || value != null) {
      onChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final hasValue = value != null;
    return Material(
      color: hasValue
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35)
          : theme.colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(AppRadius.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _open(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: hasValue
                      ? theme.colorScheme.primary.withValues(alpha: 0.18)
                      : theme.colorScheme.outlineVariant
                          .withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                alignment: Alignment.center,
                child: Icon(
                  value?.icon ?? Icons.accessibility_new_rounded,
                  color: hasValue
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                  size: 22,
                ),
              ),
              const Gap(AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.workoutFieldTargetedBodyPart,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: hasValue
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const Gap(AppSpacing.xxs),
                    Text(
                      hasValue
                          ? value!.label
                          : l10n.workoutTargetedBodyPartEmpty,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: hasValue
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onSurface,
                        fontWeight: hasValue
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(AppSpacing.sm),
              Icon(
                Icons.chevron_right_rounded,
                color: hasValue
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
