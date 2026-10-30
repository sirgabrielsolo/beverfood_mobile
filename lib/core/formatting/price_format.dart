/// Formats a price in euro using the Italian convention, e.g. `12,90 €`.
String formatPrice(double value) => '${formatAmount(value)} €';

/// Formats just the amount with a decimal comma, e.g. `12,90`, for layouts
/// that style the currency symbol separately.
String formatAmount(double value) {
  return value.toStringAsFixed(2).replaceAll('.', ',');
}
