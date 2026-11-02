/// Splits a catalogue name as the ERP writes it, upper case with the pack at
/// the end ("ESTATHE' PESCA LAT 330ML 24 PZ"), into a name for people
/// ("Estathè Pesca lattina") and its pack ("330 ml · 24 pz").
///
/// A default until the user decides how the app shows product names.
({String name, String pack}) splitProductName(String raw) {
  var text = ' ${raw.trim()} ';
  final pack = <String>[];

  final size = _size.firstMatch(text);
  if (size != null) {
    final amount = size[1]!.replaceAll('.', ',');
    pack.add('$amount ${_units[size[2]!.toUpperCase()]}');
    text = text.replaceRange(size.start, size.end, ' ');
  }
  final pieces = _pieces.firstMatch(text);
  if (pieces != null) {
    pack.add('${pieces[1]} pz');
    text = text.replaceRange(pieces.start, pieces.end, ' ');
  }

  final name = text
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .map(_word)
      .join(' ');
  return (name: name, pack: pack.join(' · '));
}

final _size = RegExp(
  r'\s(\d+(?:[.,]\d+)?)\s*(ML|CL|LT|L|GR|G|KG)(?=\s)',
  caseSensitive: false,
);
final _pieces = RegExp(r'\s(\d+)\s*PZ(?=\s)', caseSensitive: false);

const _units = {
  'ML': 'ml',
  'CL': 'cl',
  'LT': 'l',
  'L': 'l',
  'GR': 'g',
  'G': 'g',
  'KG': 'kg',
};

/// The ERP's abbreviations for containers.
const _containers = {'LAT': 'lattina', 'BT': 'bottiglia', 'VAP': 'vetro'};

const _accented = {'A': 'à', 'E': 'è', 'I': 'ì', 'O': 'ò', 'U': 'ù'};

String _word(String word) {
  final upper = word.toUpperCase();
  final container = _containers[upper];
  if (container != null) return container;
  // The ERP writes a final accent as an apostrophe: CAFFE' → Caffè.
  if (upper.length > 1 && upper.endsWith("'")) {
    final vowel = _accented[upper[upper.length - 2]];
    if (vowel != null) {
      return _capitalize(upper.substring(0, upper.length - 2)) + vowel;
    }
  }
  return word.split('-').map(_capitalize).join('-');
}

String _capitalize(String part) => part.isEmpty
    ? part
    : part[0].toUpperCase() + part.substring(1).toLowerCase();
