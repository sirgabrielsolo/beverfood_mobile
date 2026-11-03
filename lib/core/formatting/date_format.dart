const _months = [
  'gennaio',
  'febbraio',
  'marzo',
  'aprile',
  'maggio',
  'giugno',
  'luglio',
  'agosto',
  'settembre',
  'ottobre',
  'novembre',
  'dicembre',
];

/// "3 nov 2026", for lists.
String formatShortDate(DateTime date) =>
    '${date.day} ${_months[date.month - 1].substring(0, 3)} ${date.year}';

/// "3 novembre 2026, 18:28".
String formatDateTime(DateTime date) =>
    '${date.day} ${_months[date.month - 1]} ${date.year}, '
    '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
