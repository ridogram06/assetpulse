class CurrencyUtils {
  static const _symbols = {
    'BDT': '৳',
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
  };

  static String symbol(String currency) => _symbols[currency] ?? currency;

  static String format(double amount, String currency) {
    final sym = symbol(currency);
    if (amount >= 1000) {
      return '$sym${(amount / 1000).toStringAsFixed(1)}k';
    }
    return '$sym${amount.toStringAsFixed(0)}';
  }

  static String formatFull(double amount, String currency) {
    final sym = symbol(currency);
    return '$sym${amount.toStringAsFixed(2)}';
  }

  static String perDay(double totalCost, int days) {
    if (days <= 0) return '৳0/দিন';
    return '৳${(totalCost / days).toStringAsFixed(2)}/দিন';
  }

  static String perMonth(double cost, String billingCycle) {
    switch (billingCycle) {
      case 'quarterly': return '৳${(cost / 3).toStringAsFixed(0)}/মাস';
      case 'annually':  return '৳${(cost / 12).toStringAsFixed(0)}/মাস';
      default:          return '৳${cost.toStringAsFixed(0)}/মাস';
    }
  }
}
