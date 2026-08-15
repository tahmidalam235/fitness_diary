import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/app_section_header.dart';
import '../../data/notification_service.dart';
import '../../data/settings_service.dart';
import '../../data/theme_service.dart';

/// App Settings. Toggles for theme mode, weight units, and notifications.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeSvc = getIt<ThemeService>();
    final settingsSvc = getIt<SettingsService>();
    final notifySvc = getIt<NotificationService>();

    return AppScaffold(
      title: 'Settings',
      useNavigationRail: true,
      body: ListenableBuilder(
        listenable: Listenable.merge([themeSvc, settingsSvc]),
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              _SettingsHero(),
              const Gap(AppSpacing.xl),
              const AppSectionHeader(
                title: 'APPEARANCE',
                icon: Icons.palette_outlined,
              ),
              const SizedBox(height: AppSpacing.xs),
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
              const AppSectionHeader(
                title: 'UNITS',
                icon: Icons.straighten_outlined,
              ),
              const SizedBox(height: AppSpacing.xs),
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
              const AppSectionHeader(
                title: 'REMINDERS',
                icon: Icons.notifications_active_outlined,
              ),
              const SizedBox(height: AppSpacing.xs),
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
              const Gap(AppSpacing.xl),
            ],
          );
        },
      ),
    );
  }
}

/// Settings hero: gradient banner reminding the user that settings
/// personalize their workout tracking experience.
class _SettingsHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppTheme.deepGradient,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.settings_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'PREFERENCES',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Make it yours',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tune your app to match your training style.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
      title: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.1,
        ),
      ),
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
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      leading: _IconBox(icon: icon),
      title: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.1,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(
                alpha: 0.55,
              ),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 0.2,
              ),
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
    final theme = Theme.of(context);
    return ListTile(
      leading: _IconBox(icon: icon),
      title: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.1,
        ),
      ),
      trailing: DropdownButton<T>(
        value: value,
        underline: const SizedBox(),
        borderRadius: BorderRadius.circular(AppRadius.md),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
        items: items.map((i) {
          return DropdownMenuItem(
            value: i,
            child: Text(
              itemLabel(i),
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
          );
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
      width: 38,
      height: 38,
      decoration: const BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.sm)),
        boxShadow: [
          BoxShadow(
            color: Color(0x406366F1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 18, color: Colors.white),
    );
  }
}