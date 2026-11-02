/// An Italian mobile number as the API stores it (`+393334821756`), grouped
/// for reading: `+39 333 482 1756`. Anything else is returned as is.
String formatPhone(String? phone) {
  if (phone == null) return '';
  final match = RegExp(r'^\+39(\d{3})(\d{3})(\d+)$').firstMatch(phone);
  return match == null ? phone : '+39 ${match[1]} ${match[2]} ${match[3]}';
}
