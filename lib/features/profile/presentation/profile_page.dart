import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:beverfood_mobile/app/router.dart';
import 'package:beverfood_mobile/app/theme/app_colors.dart';
import 'package:beverfood_mobile/app/theme/app_palette.dart';
import 'package:beverfood_mobile/app/theme/app_radii.dart';
import 'package:beverfood_mobile/app/theme/theme_mode_controller.dart';
import 'package:beverfood_mobile/core/formatting/phone_format.dart';
import 'package:beverfood_mobile/core/network/api_client.dart';
import 'package:beverfood_mobile/features/auth/data/auth_controller.dart';
import 'package:beverfood_mobile/features/auth/data/auth_repository.dart';
import 'package:beverfood_mobile/features/auth/models/account.dart';
import 'package:beverfood_mobile/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:beverfood_mobile/features/auth/presentation/widgets/contact_verification.dart';

/// The account (E): who's signed in and their state, the contacts and the
/// address, the theme under "Aspetto", then Esci and Elimina account (off
/// for the test account). Grouped like a settings list.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final account = AuthScope.of(context).account;

    return Scaffold(
      appBar: AppBar(title: const Text('Profilo')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          if (account != null) ...[
            _AccountCard(account: account),
            const _SectionHeader('Account'),
            _AccountRows(account: account),
          ],
          const _SectionHeader('Aspetto'),
          const _ThemeRows(),
          const SizedBox(height: 28),
          WideButton(
            label: 'Esci',
            primary: false,
            onPressed: () => AuthScope.read(context).signOut(),
          ),
          const SizedBox(height: 10),
          WideButton(
            label: 'Elimina account',
            destructive: true,
            onPressed: account == null || account.isTest
                ? null
                : () => _confirmDelete(context),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Eliminare l'account?"),
        content: const Text(
          'Cancelliamo i tuoi dati personali e chiudiamo l\'accesso su tutti '
          'i dispositivi. Gli ordini già inviati restano per gli obblighi '
          'fiscali. Non si può annullare.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.brand),
            child: const Text(
              'Elimina',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await AuthScope.read(context).deleteAccount();
    } on ApiException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final (
      String status,
      Color background,
      Color foreground,
    ) = switch (account.status) {
      AccountStatus.approved => (
        'APPROVATO',
        palette.success,
        palette.onSuccess,
      ),
      AccountStatus.pending => (
        'IN VERIFICA',
        palette.warning,
        palette.onWarning,
      ),
      AccountStatus.rejected => (
        'DA CORREGGERE',
        palette.navIndicator,
        palette.brandText,
      ),
      AccountStatus.suspended => (
        'SOSPESO',
        palette.navIndicator,
        palette.brandText,
      ),
      AccountStatus.registered => (
        'PROFILO DA COMPLETARE',
        palette.navIndicator,
        palette.brandText,
      ),
    };
    // The client number sits under the name, so the badge stays short.
    final company = [
      account.companyName,
      if (account.vatNumber != null) 'P.IVA ${account.vatNumber}',
      if (account.erpClientId != null) 'Cliente ${account.erpClientId}',
    ].whereType<String>().join(' · ');

    return Material(
      color: palette.surface,
      borderRadius: AppRadii.card,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // The status closes the name's line, keeping the card short.
            Row(
              children: [
                Expanded(
                  child: Text(
                    account.fullName ?? 'Il tuo account',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _Pill(status, background, foreground),
              ],
            ),
            if (company.isNotEmpty)
              Text(
                company,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: palette.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.text, this.background, this.foreground);

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadii.badge,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
            color: foreground,
          ),
        ),
      ),
    );
  }
}

/// Section label above a group of rows, as in system settings.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.9,
          color: context.palette.textSecondary,
        ),
      ),
    );
  }
}

/// A rounded group of rows separated by hairlines.
class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.palette.surface,
      borderRadius: AppRadii.card,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final (i, child) in children.indexed) ...[
            if (i > 0) const Divider(indent: 16, endIndent: 16),
            child,
          ],
        ],
      ),
    );
  }
}

/// Label on the left, value (and a chevron when tappable) on the right.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.title,
    required this.value,
    this.onTap,
    this.verified = false,
    this.highlight = false,
  });

  final String title;
  final String value;
  final VoidCallback? onTap;
  final bool verified;

  /// Brand-colored value: something to do ("Aggiungi", "Completa").
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
          child: Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: highlight
                        ? palette.brandText
                        : palette.textSecondary,
                  ),
                ),
              ),
              if (verified) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.verified_rounded,
                  size: 18,
                  color: palette.onSuccess,
                ),
              ],
              if (onTap != null) ...[
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, color: palette.textSecondary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountRows extends StatelessWidget {
  const _AccountRows({required this.account});

  final Account account;

  Future<void> _addEmail(BuildContext context) async {
    final field = TextEditingController();
    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aggiungi email'),
        content: TextField(
          controller: field,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(hintText: 'nome@azienda.it'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(field.text.trim()),
            child: const Text('Invia codice'),
          ),
        ],
      ),
    );
    field.dispose();
    if (email == null || email.isEmpty || !context.mounted) return;
    try {
      await verifyContact(context, CodeChannel.email, email);
    } on ApiException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final address = account.address;
    final editable = account.profileEditable;
    final (String? action, String? actionValue) = switch (account.status) {
      AccountStatus.registered => ('Profilo', 'Completa'),
      AccountStatus.rejected => ('Profilo', 'Correggi i dati'),
      AccountStatus.pending => ('Dati inviati', 'Modifica'),
      _ => (null, null),
    };

    return _Group(
      children: [
        if (action != null)
          _InfoRow(
            title: action,
            value: actionValue!,
            highlight: true,
            onTap: () => context.push(AppRoutes.completeProfile),
          ),
        _InfoRow(
          title: 'Cellulare',
          value: account.phoneVerified
              ? formatPhone(account.phone)
              : 'Da verificare',
          verified: account.phoneVerified,
          highlight: !account.phoneVerified,
          onTap: account.phoneVerified
              ? null
              : () => context.push(AppRoutes.completeProfile),
        ),
        _InfoRow(
          title: 'Email',
          value: account.emailVerified ? account.email! : 'Aggiungi',
          verified: account.emailVerified,
          highlight: !account.emailVerified,
          onTap: account.emailVerified ? null : () => _addEmail(context),
        ),
        _InfoRow(
          title: 'Consegna',
          value: address?.oneLine ?? 'Da completare',
          highlight: address == null,
          onTap: address == null || editable
              ? () => context.push(AppRoutes.completeProfile)
              : () => context.push(AppRoutes.editAddress),
        ),
      ],
    );
  }
}

class _ThemeRows extends StatelessWidget {
  const _ThemeRows();

  @override
  Widget build(BuildContext context) {
    final themeMode = ThemeModeScope.of(context);
    final followDevice = themeMode.mode == ThemeMode.system;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _Group(
      children: [
        _SwitchRow(
          title: 'Segui impostazione del dispositivo',
          value: followDevice,
          // Turning it off keeps the theme currently on screen.
          onChanged: (follow) => themeMode.setMode(
            follow
                ? ThemeMode.system
                : (isDark ? ThemeMode.dark : ThemeMode.light),
          ),
        ),
        _SwitchRow(
          title: 'Modalità scura',
          value: isDark,
          onChanged: followDevice
              ? null
              : (dark) =>
                    themeMode.setMode(dark ? ThemeMode.dark : ThemeMode.light),
        ),
      ],
    );
  }
}

/// Setting row: title and switch. The whole row is tappable.
class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
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
            padding: const EdgeInsets.fromLTRB(16, 6, 12, 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
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
