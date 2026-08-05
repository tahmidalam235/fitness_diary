import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../data/notification_service.dart';
import '../../data/settings_service.dart';
import '../../data/theme_service.dart';

/// App Settings. Toggles for theme mode, weight units, and notifications.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final themeSvc = getIt<ThemeService>();
    final settingsSvc = getIt<SettingsService>();
    final notifySvc = getIt<NotificationService>();

    return AppScaffold(
      title: l10n.settingsTitle,
      useNavigationRail: true,
      body: ListenableBuilder(
        listenable: Listenable.merge([themeSvc, settingsSvc]),
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              _SectionHeader(title: 'Appearance'),
              const Gap(AppSpacing.sm),
              _SettingsCard(
                children: [
                  _ToggleRow(
                    label: 'Dark Mode',
                    icon: Icons.dark_mode_outlined,
                    value: themeSvc.mode == ThemeMode.dark,
                    onChanged: (v) => themeSvc.setDark(v),
                  ),
                ],
              ),
              const Gap(AppSpacing.lg),
              _SectionHeader(title: 'Units'),
              const Gap(AppSpacing.sm),
              _SettingsCard(
                children: [
                  _PickerRow<WeightUnit>(
                    label: 'Weight Unit',
                    icon: Icons.fitness_center_rounded,
                    value: settingsSvc.unit,
                    items: WeightUnit.values,
                    itemLabel: (u) => u.label,
                    onChanged: (u) => settingsSvc.setUnit(u),
                  ),
                ],
              ),
              const Gap(AppSpacing.lg),
              _SectionHeader(title: 'Reminders'),
              const Gap(AppSpacing.sm),
              _SettingsCard(
                children: [
                  _ToggleRow(
                    label: 'Daily Workout Reminders',
                    icon: Icons.notifications_active_outlined,
                    value: settingsSvc.notifications,
                    onChanged: (v) async {
                      if (v) {
                        final ok = await notifySvc.requestPermission();
                        if (!ok) return;
                        await notifySvc.scheduleDaily(settingsSvc.reminderTime);
                      } else {
                        await notifySvc.cancelDaily();
                      }
                      await settingsSvc.setNotifications(v);
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  _ActionRow(
                    label: 'Reminder Time',
                    icon: Icons.access_time_rounded,
                    value: settingsSvc.reminderTime.format(context),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: settingsSvc.reminderTime,
                      );
                      if (picked != null) {
                        await settingsSvc.setReminderTime(picked);
                        if (settingsSvc.notifications) {
                          await notifySvc.scheduleDaily(picked);
                        }
                      }
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  _ActionRow(
                    label: 'Test Notification',
                    icon: Icons.send_rounded,
                    value: 'Send now',
                    onTap: () => notifySvc.sendTestNotification(),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(children: children),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _IconBox(icon: icon),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.label,
    required this.icon,
    required this.value,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: _IconBox(icon: icon),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Gap(AppSpacing.xs),
          const Icon(Icons.chevron_right_rounded, size: 20),
        ],
      ),
    );
  }
}

class _PickerRow<T> extends StatelessWidget {
  const _PickerRow({
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final T value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _IconBox(icon: icon),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: DropdownButton<T>(
        value: value,
        underline: const SizedBox(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
        items: items.map((i) {
          return DropdownMenuItem(value: i, child: Text(itemLabel(i)));
        }).toList(),
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 20),
    );
  }
}
