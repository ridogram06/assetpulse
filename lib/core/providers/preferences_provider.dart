import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supported display currencies. Symbols intentionally short.
class Currency {
  final String code;
  final String symbol;
  final String label;
  const Currency(this.code, this.symbol, this.label);

  static const bdt = Currency('BDT', '৳',  'টাকা (BDT)');
  static const usd = Currency('USD', '\$', 'Dollar (USD)');
  static const inr = Currency('INR', '₹',  'Rupee (INR)');
  static const eur = Currency('EUR', '€',  'Euro (EUR)');

  static const all = [bdt, usd, inr, eur];

  static Currency fromCode(String? code) =>
      all.firstWhere((c) => c.code == code, orElse: () => bdt);
}

/// Format a numeric amount with a specific currency.
String formatMoney(num amount, Currency c, {int decimals = 0}) {
  final v = amount.toStringAsFixed(decimals);
  return '${c.symbol}$v';
}

/// Resolve the right symbol for a stored asset.currency code (e.g. 'BDT').
/// Falls back to the active display preference when the code is unknown.
String currencySymbolFor(String? assetCurrencyCode, Currency preference) {
  if (assetCurrencyCode == null || assetCurrencyCode.isEmpty) {
    return preference.symbol;
  }
  return Currency.fromCode(assetCurrencyCode).symbol;
}

// =============================================================================
// CURRENCY
// =============================================================================
class CurrencyNotifier extends StateNotifier<Currency> {
  CurrencyNotifier() : super(Currency.bdt) {
    _load();
  }

  static const _key = 'pref_currency_code';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = Currency.fromCode(prefs.getString(_key));
  }

  Future<void> set(Currency c) async {
    state = c;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, c.code);
  }
}

final currencyProvider =
    StateNotifierProvider<CurrencyNotifier, Currency>((_) => CurrencyNotifier());

// =============================================================================
// THEME
// =============================================================================
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.dark) {
    _load();
  }

  static const _key = 'pref_theme_mode';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    state = _parse(raw);
  }

  Future<void> set(ThemeMode m) async {
    state = m;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, m.name);
  }

  ThemeMode _parse(String? raw) {
    switch (raw) {
      case 'light':  return ThemeMode.light;
      case 'system': return ThemeMode.system;
      case 'dark':
      default:       return ThemeMode.dark;
    }
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((_) => ThemeModeNotifier());

extension ThemeModeLabel on ThemeMode {
  String get banglaLabel {
    switch (this) {
      case ThemeMode.light:  return 'লাইট';
      case ThemeMode.system: return 'সিস্টেম';
      case ThemeMode.dark:   return 'ডার্ক';
    }
  }
}
