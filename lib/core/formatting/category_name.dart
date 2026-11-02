/// A category name as the ERP writes it ("VINI E SPUMANTI", "CAFFE'") in
/// the sentence case Italian shops use: "Vini e spumanti", "Caffè".
String categoryLabel(String raw) {
  final words = raw.trim().toLowerCase().split(RegExp(r'\s+'));
  final text = words.map(_accented).join(' ');
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1);
}

const _accents = {'a': 'à', 'e': 'è', 'i': 'ì', 'o': 'ò', 'u': 'ù'};

/// The ERP writes a final accent as an apostrophe: CAFFE' → caffè.
String _accented(String word) {
  if (word.length < 2 || !word.endsWith("'")) return word;
  final vowel = _accents[word[word.length - 2]];
  if (vowel == null) return word;
  return word.substring(0, word.length - 2) + vowel;
}
