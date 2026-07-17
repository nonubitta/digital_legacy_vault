String displayCurrencyLabel(String currencyCode) {
  return currencyCode.trim().toUpperCase() == 'USD' ? r'$' : currencyCode.trim().toUpperCase();
}

String formatCurrencyAmount(String currencyCode, num amount) {
  final label = displayCurrencyLabel(currencyCode);
  return '$label ${amount.toStringAsFixed(2)}';
}
