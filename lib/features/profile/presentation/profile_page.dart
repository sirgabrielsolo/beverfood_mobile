import 'package:flutter/material.dart';

import 'package:beverfood_mobile/app/theme/app_palette.dart';
import 'package:beverfood_mobile/app/theme/app_radii.dart';
import 'package:beverfood_mobile/app/theme/theme_mode_controller.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = ThemeModeScope.of(context);
    final followDevice = themeMode.mode == ThemeMode.system;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Profilo')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const _ProfileHeader(),
          const _SectionTitle('Aspetto'),
          // A Material (not a DecoratedBox) so the rows' tap ripple shows.
          Material(
            color: context.palette.surface,
            borderRadius: AppRadii.card,
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _SwitchTile(
                  title: 'Segui impostazione del dispositivo',
                  value: followDevice,
                  // Turning it off keeps the theme currently on screen.
                  onChanged: (follow) => themeMode.setMode(
                    follow
                        ? ThemeMode.system
                        : (isDark ? ThemeMode.dark : ThemeMode.light),
                  ),
                ),
                const Divider(indent: 16, endIndent: 16),
                _SwitchTile(
                  title: 'Modalità scura',
                  value: isDark,
                  onChanged: followDevice
                      ? null
                      : (dark) => themeMode.setMode(
                          dark ? ThemeMode.dark : ThemeMode.light,
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

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: primary.withValues(alpha: 0.15),
          child: Icon(Icons.person_rounded, size: 30, color: primary),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Text(
            'Area personale',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 28, 4, 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Setting row: title and switch. The whole row is tappable.
class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;

  /// `null` disables the row.
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;

    return MergeSemantics(
      child: InkWell(
        onTap: enabled ? () => onChanged!(!value) : null,
        child: Opacity(
          opacity: enabled ? 1 : 0.5,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Switch(value: value, onChanged: onChanged),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
