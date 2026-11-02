import 'dart:async';

import 'package:flutter/material.dart';

import 'package:beverfood_mobile/app/theme/app_colors.dart';
import 'package:beverfood_mobile/app/theme/app_palette.dart';
import 'package:beverfood_mobile/app/theme/app_radii.dart';
import 'package:beverfood_mobile/core/network/api_client.dart';
import 'package:beverfood_mobile/features/auth/data/auth_controller.dart';
import 'package:beverfood_mobile/features/auth/models/account.dart';
import 'package:beverfood_mobile/features/auth/presentation/widgets/auth_widgets.dart';

/// A delivery address in the province of Torino: comune from the list, the
/// street searched as you type (or typed by hand when it isn't listed),
/// civico, CAP (filled in when there's only one) and optional notes.
///
/// Reports a complete address through [onChanged], or null while something
/// is missing. [errors] shows the server's messages by field.
class AddressForm extends StatefulWidget {
  const AddressForm({
    super.key,
    this.initial,
    required this.onChanged,
    this.errors = const {},
  });

  final DeliveryAddress? initial;
  final ValueChanged<DeliveryAddress?> onChanged;
  final Map<String, String> errors;

  @override
  State<AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<AddressForm> {
  final _street = TextEditingController();
  final _civic = TextEditingController();
  final _notes = TextEditingController();
  final _streetFocus = FocusNode();

  List<Comune>? _comuni;
  String? _loadError;
  Comune? _comune;
  Street? _picked;
  bool _unlisted = false;
  String? _cap;

  List<Street> _suggestions = const [];
  Timer? _debounce;
  int _searchId = 0;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _comune = Comune(
        istat: initial.comuneIstat,
        name: initial.comune,
        caps: [initial.cap],
      );
      _street.text = initial.street;
      _unlisted = initial.streetUnlisted;
      if (!_unlisted) _picked = Street(name: initial.street, caps: const []);
      _civic.text = initial.civic;
      _notes.text = initial.notes ?? '';
      _cap = initial.cap;
    }
    _civic.addListener(_emit);
    _notes.addListener(_emit);
    _loadComuni();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _street.dispose();
    _civic.dispose();
    _notes.dispose();
    _streetFocus.dispose();
    super.dispose();
  }

  Future<void> _loadComuni() async {
    try {
      final comuni = await AuthScope.read(context).repository.comuni();
      if (!mounted) return;
      setState(() {
        _comuni = comuni;
        _loadError = null;
        // The saved comune with all its CAPs.
        final current = _comune;
        if (current != null) {
          _comune = comuni.firstWhere(
            (c) => c.istat == current.istat,
            orElse: () => current,
          );
        }
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _loadError = error.message);
    }
  }

  /// The CAPs to choose from: the street's (Torino), else the comune's.
  List<String> get _capOptions {
    final streetCaps = _picked?.caps ?? const [];
    if (streetCaps.isNotEmpty) return streetCaps;
    return _comune?.caps ?? const [];
  }

  void _emit() {
    final comune = _comune;
    final street = _street.text.trim();
    final civic = _civic.text.trim();
    final options = _capOptions;
    final cap = options.length == 1 ? options.single : _cap;
    final complete =
        comune != null &&
        street.isNotEmpty &&
        (_picked != null || _unlisted) &&
        civic.isNotEmpty &&
        cap != null &&
        comune.caps.contains(cap);
    widget.onChanged(
      complete
          ? DeliveryAddress(
              comuneIstat: comune.istat,
              comune: comune.name,
              street: street,
              streetUnlisted: _picked == null,
              civic: civic,
              cap: cap,
              notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
            )
          : null,
    );
  }

  Future<void> _pickComune() async {
    final comuni = _comuni;
    if (comuni == null) return;
    final chosen = await Navigator.of(context).push<Comune>(
      MaterialPageRoute(builder: (_) => _ComunePickerPage(comuni: comuni)),
    );
    if (chosen == null || chosen.istat == _comune?.istat) return;
    setState(() {
      _comune = chosen;
      _street.clear();
      _picked = null;
      _suggestions = const [];
      _cap = chosen.caps.length == 1 ? chosen.caps.single : null;
    });
    _emit();
    _streetFocus.requestFocus();
  }

  void _onStreetChanged(String text) {
    if (_picked != null && text != _picked!.name) {
      setState(() {
        _picked = null;
        if (_comune != null && _comune!.caps.length > 1) _cap = null;
      });
    }
    _emit();
    _debounce?.cancel();
    final comune = _comune;
    if (_unlisted || comune == null || text.trim().length < 2) {
      if (_suggestions.isNotEmpty) setState(() => _suggestions = const []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      final id = ++_searchId;
      try {
        final found = await AuthScope.read(
          context,
        ).repository.streets(comune.istat, text);
        if (mounted && id == _searchId && _picked == null) {
          setState(() => _suggestions = found);
        }
      } on ApiException {
        // Keep typing; the next keystroke searches again.
      }
    });
  }

  void _pickStreet(Street street) {
    _street.text = street.name;
    setState(() {
      _picked = street;
      _suggestions = const [];
      final options = _capOptions;
      _cap = options.length == 1 ? options.single : null;
    });
    _emit();
    FocusScope.of(context).nextFocus();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final errors = widget.errors;
    final capOptions = _capOptions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FieldButton(
          label: 'Comune',
          value: _comune?.name,
          trailing: _comune == null ? null : 'TO',
          hint: _comuni == null && _loadError == null
              ? 'Caricamento…'
              : 'Scegli il comune',
          error: _loadError ?? errors['comune_istat'],
          onTap: _comuni == null ? _loadComuni : _pickComune,
        ),
        const SizedBox(height: 14),
        LabeledField(
          label: 'Via',
          controller: _street,
          focusNode: _streetFocus,
          enabled: _comune != null,
          hint: _unlisted ? 'Scrivi la via' : 'Cerca la via',
          error: errors['street'],
          textCapitalization: TextCapitalization.words,
          suffix: _picked != null
              ? Icon(Icons.check_rounded, color: palette.onSuccess)
              : const Icon(Icons.search_rounded),
          onChanged: _onStreetChanged,
        ),
        if (_suggestions.isNotEmpty) ...[
          const SizedBox(height: 6),
          Material(
            color: palette.surface,
            borderRadius: AppRadii.field,
            elevation: 3,
            shadowColor: Colors.black26,
            child: Column(
              children: [
                for (final (i, street) in _suggestions.take(6).indexed) ...[
                  if (i > 0) const Divider(height: 1),
                  InkWell(
                    onTap: () => _pickStreet(street),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 11,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              street.name,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            _comune?.name ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: palette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 4),
        _UnlistedToggle(
          value: _unlisted,
          enabled: _comune != null,
          onChanged: (value) {
            setState(() {
              _unlisted = value;
              _suggestions = const [];
              if (value) _picked = null;
            });
            _emit();
          },
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: LabeledField(
                label: 'Civico',
                controller: _civic,
                hint: 'es. 12/B',
                error: errors['civic'],
                maxLength: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: capOptions.length <= 1
                  ? _FieldButton(
                      label: 'CAP',
                      value: capOptions.isEmpty ? null : capOptions.single,
                      hint: '—',
                      error: errors['cap'],
                    )
                  : _CapDropdown(
                      options: capOptions,
                      value: capOptions.contains(_cap) ? _cap : null,
                      error: errors['cap'],
                      onChanged: (cap) {
                        setState(() => _cap = cap);
                        _emit();
                      },
                    ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        LabeledField(
          label: 'Indicazioni per il corriere (facoltative)',
          controller: _notes,
          hint: 'Cortile, citofono, orari…',
          error: errors['notes'],
          maxLength: 300,
        ),
        const SizedBox(height: 10),
        Text(
          'Consegniamo solo in provincia di Torino. Elenco delle vie © '
          'OpenStreetMap.',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: palette.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Looks like a [LabeledField] but opens a picker (or shows a fixed value).
class _FieldButton extends StatelessWidget {
  const _FieldButton({
    required this.label,
    required this.value,
    required this.hint,
    this.trailing,
    this.error,
    this.onTap,
  });

  final String label;
  final String? value;
  final String hint;
  final String? trailing;
  final String? error;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: palette.textSecondary,
            ),
          ),
        ),
        Material(
          color: palette.surface,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadii.field,
            side: BorderSide(
              color: error == null ? palette.line : AppColors.brand,
              width: 1.5,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadii.field,
            child: SizedBox(
              height: 48,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        value ?? hint,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: value == null
                              ? FontWeight.w600
                              : FontWeight.w700,
                          color: value == null
                              ? palette.textSecondary
                              : palette.textPrimary,
                        ),
                      ),
                    ),
                    if (trailing != null)
                      Text(
                        trailing!,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: palette.textSecondary,
                        ),
                      ),
                    if (onTap != null) ...[
                      const SizedBox(width: 6),
                      Icon(
                        Icons.expand_more_rounded,
                        color: palette.textSecondary,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(left: 2, top: 6),
            child: Text(
              error!,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: palette.brandText,
              ),
            ),
          ),
      ],
    );
  }
}

class _CapDropdown extends StatelessWidget {
  const _CapDropdown({
    required this.options,
    required this.value,
    required this.onChanged,
    this.error,
  });

  final List<String> options;
  final String? value;
  final ValueChanged<String?> onChanged;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    OutlineInputBorder border(Color color, [double width = 1.5]) =>
        OutlineInputBorder(
          borderRadius: AppRadii.field,
          borderSide: BorderSide(color: color, width: width),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text(
            'CAP',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: palette.textSecondary,
            ),
          ),
        ),
        DropdownButtonFormField<String>(
          initialValue: value,
          hint: const Text('Scegli'),
          isExpanded: true,
          items: [
            for (final cap in options)
              DropdownMenuItem(value: cap, child: Text(cap)),
          ],
          onChanged: onChanged,
          style: TextStyle(
            fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: palette.textPrimary,
          ),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 13,
            ),
            enabledBorder: border(
              error == null ? palette.line : AppColors.brand,
            ),
            focusedBorder: border(AppColors.brand, 2),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(left: 2, top: 6),
            child: Text(
              error!,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: palette.brandText,
              ),
            ),
          ),
      ],
    );
  }
}

class _UnlistedToggle extends StatelessWidget {
  const _UnlistedToggle({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: InkWell(
        onTap: enabled ? () => onChanged(!value) : null,
        borderRadius: AppRadii.button,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Checkbox(
                value: value,
                onChanged: enabled ? (v) => onChanged(v ?? false) : null,
                activeColor: AppColors.brand,
                visualDensity: VisualDensity.compact,
              ),
              Text(
                'La via non è in elenco',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: context.palette.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-screen search over the province's comuni.
class _ComunePickerPage extends StatefulWidget {
  const _ComunePickerPage({required this.comuni});

  final List<Comune> comuni;

  @override
  State<_ComunePickerPage> createState() => _ComunePickerPageState();
}

class _ComunePickerPageState extends State<_ComunePickerPage> {
  final _query = TextEditingController();

  static String _fold(String text) {
    const from = 'àáâäèéêëìíîïòóôöùúûü';
    const to = 'aaaaeeeeiiiioooouuuu';
    final lower = text.toLowerCase();
    final out = StringBuffer();
    for (final rune in lower.runes) {
      final char = String.fromCharCode(rune);
      final i = from.indexOf(char);
      out.write(i >= 0 ? to[i] : char);
    }
    return out.toString().replaceAll("'", ' ').replaceAll('-', ' ');
  }

  @override
  void initState() {
    super.initState();
    _query.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final q = _fold(_query.text.trim());
    final list = q.isEmpty
        ? widget.comuni
        : [
            ...widget.comuni.where((c) => _fold(c.name).startsWith(q)),
            ...widget.comuni.where(
              (c) => !_fold(c.name).startsWith(q) && _fold(c.name).contains(q),
            ),
          ];

    return Scaffold(
      appBar: AppBar(title: const Text('Comune')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _query,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'Cerca il comune',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Nessun comune della provincia di Torino con questo nome.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: palette.textSecondary),
                    ),
                  )
                : ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (context, index) =>
                        const Divider(indent: 16, endIndent: 16),
                    itemBuilder: (context, index) {
                      final comune = list[index];
                      final caps = comune.caps.length == 1
                          ? comune.caps.single
                          : '${comune.caps.first}–${comune.caps.last}';
                      return ListTile(
                        title: Text(
                          comune.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        trailing: Text(caps),
                        onTap: () => Navigator.of(context).pop(comune),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
