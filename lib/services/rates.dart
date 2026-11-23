// Default brands, rates, coverage and app settings for PaintEasy.
//
// Defaults are STARTING VALUES ONLY — every one of them is editable in
// Settings, and the UI labels the rates screen with a note to confirm
// defaults with a real painter before relying on them.
// Rates are entered in the selected currency; there is NO live FX
// conversion in v1 (offline app).
//
// Research basis (Nov 2026):
// - Coverage: manufacturer TDS 11-16 m2/L (~118-172 sq ft) theoretical;
//   practical guides say emulsion 90-110 sq ft/L per coat -> 100 default.
//   Primer 120, distemper 110.
// - Labour: Pakistani sources, new interior work Rs 25-40/sq ft,
//   repaint Rs 15-25/sq ft -> Rs 25 default.
// - Brand rates (PKR/L, starting values only): Berger 900, Nippon 950,
//   Diamond 750, Brighto 700, Dulux 1200, Master 650. Primer 450/L.
//   Putty Rs 5/sq ft, on by default.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/estimate.dart';

/// Supported currencies. The symbol is display-only; rates are entered
/// in the selected currency.
const Map<String, String> currencySymbols = <String, String>{
  'PKR': 'Rs',
  'USD': '\$',
  'INR': '₹',
  'AED': 'AED',
  'GBP': '£',
  'EUR': '€',
};

const List<String> supportedCurrencies = <String>[
  'PKR',
  'USD',
  'INR',
  'AED',
  'GBP',
  'EUR',
];

const List<String> supportedBrands = <String>[
  'Berger',
  'Nippon',
  'Diamond',
  'Brighto',
  'Dulux',
  'Master',
];

/// Default brand rates (per liter) and coverage (sq ft per liter per coat).
final Map<String, BrandRate> defaultBrandRates = <String, BrandRate>{
  'Berger': BrandRate(brand: 'Berger', ratePerLiter: 900, coveragePerLiterSqFt: 100),
  'Nippon': BrandRate(brand: 'Nippon', ratePerLiter: 950, coveragePerLiterSqFt: 100),
  'Diamond': BrandRate(brand: 'Diamond', ratePerLiter: 750, coveragePerLiterSqFt: 100),
  'Brighto': BrandRate(brand: 'Brighto', ratePerLiter: 700, coveragePerLiterSqFt: 100),
  'Dulux': BrandRate(brand: 'Dulux', ratePerLiter: 1200, coveragePerLiterSqFt: 100),
  'Master': BrandRate(brand: 'Master', ratePerLiter: 650, coveragePerLiterSqFt: 100),
};

/// Default coverage (sq ft / liter / coat) by paint type.
const double defaultEmulsionCoverageSqFt = 100;
const double defaultPrimerCoverageSqFt = 120;
const double defaultDistemperCoverageSqFt = 110;

/// Default labour rate per sq ft.
const double defaultLabourRatePerSqFt = 25;

/// Default primer rate per liter.
const double defaultPrimerRatePerLiter = 450;

/// Default putty rate per sq ft.
const double defaultPuttyRatePerSqFt = 5;

/// Default standard door size: 21 sq ft (7 ft x 3 ft).
const double defaultDoorAreaSqFt = 21;

/// Default standard window size: 16 sq ft (4 ft x 4 ft).
const double defaultWindowAreaSqFt = 16;

/// Metric equivalents of the standard sizes (for display in metre mode):
/// a standard door 2.1 m x 0.9 m = 1.89 m2, a standard window
/// 1.2 m x 1.2 m = 1.44 m2 (close to 21 / 16 sq ft).
const double defaultDoorAreaSqM = 1.89;
const double defaultWindowAreaSqM = 1.44;

/// App-wide settings, stored locally.
class AppSettings {
  AppSettings({
    this.currency = 'PKR',
    this.defaultUnit = 'ft',
    this.doorAreaSqFt = defaultDoorAreaSqFt,
    this.windowAreaSqFt = defaultWindowAreaSqFt,
    this.labourRatePerSqFt = defaultLabourRatePerSqFt,
    this.puttyRatePerSqFt = defaultPuttyRatePerSqFt,
    this.primerRatePerLiter = defaultPrimerRatePerLiter,
    this.emulsionCoverageSqFt = defaultEmulsionCoverageSqFt,
    this.primerCoverageSqFt = defaultPrimerCoverageSqFt,
    this.distemperCoverageSqFt = defaultDistemperCoverageSqFt,
    this.puttyEnabledByDefault = true,
  });

  final String currency;
  final String defaultUnit;
  final double doorAreaSqFt;
  final double windowAreaSqFt;
  final double labourRatePerSqFt;
  final double puttyRatePerSqFt;
  final double primerRatePerLiter;
  final double emulsionCoverageSqFt;
  final double primerCoverageSqFt;
  final double distemperCoverageSqFt;
  final bool puttyEnabledByDefault;

  AppSettings copyWith({
    String? currency,
    String? defaultUnit,
    double? doorAreaSqFt,
    double? windowAreaSqFt,
    double? labourRatePerSqFt,
    double? puttyRatePerSqFt,
    double? primerRatePerLiter,
    double? emulsionCoverageSqFt,
    double? primerCoverageSqFt,
    double? distemperCoverageSqFt,
    bool? puttyEnabledByDefault,
  }) {
    return AppSettings(
      currency: currency ?? this.currency,
      defaultUnit: defaultUnit ?? this.defaultUnit,
      doorAreaSqFt: doorAreaSqFt ?? this.doorAreaSqFt,
      windowAreaSqFt: windowAreaSqFt ?? this.windowAreaSqFt,
      labourRatePerSqFt: labourRatePerSqFt ?? this.labourRatePerSqFt,
      puttyRatePerSqFt: puttyRatePerSqFt ?? this.puttyRatePerSqFt,
      primerRatePerLiter: primerRatePerLiter ?? this.primerRatePerLiter,
      emulsionCoverageSqFt:
          emulsionCoverageSqFt ?? this.emulsionCoverageSqFt,
      primerCoverageSqFt: primerCoverageSqFt ?? this.primerCoverageSqFt,
      distemperCoverageSqFt:
          distemperCoverageSqFt ?? this.distemperCoverageSqFt,
      puttyEnabledByDefault:
          puttyEnabledByDefault ?? this.puttyEnabledByDefault,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'currency': currency,
        'defaultUnit': defaultUnit,
        'doorAreaSqFt': doorAreaSqFt,
        'windowAreaSqFt': windowAreaSqFt,
        'labourRatePerSqFt': labourRatePerSqFt,
        'puttyRatePerSqFt': puttyRatePerSqFt,
        'primerRatePerLiter': primerRatePerLiter,
        'emulsionCoverageSqFt': emulsionCoverageSqFt,
        'primerCoverageSqFt': primerCoverageSqFt,
        'distemperCoverageSqFt': distemperCoverageSqFt,
        'puttyEnabledByDefault': puttyEnabledByDefault,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      currency: json['currency'] as String? ?? 'PKR',
      defaultUnit: json['defaultUnit'] as String? ?? 'ft',
      doorAreaSqFt: (json['doorAreaSqFt'] as num?)?.toDouble() ??
          defaultDoorAreaSqFt,
      windowAreaSqFt: (json['windowAreaSqFt'] as num?)?.toDouble() ??
          defaultWindowAreaSqFt,
      labourRatePerSqFt: (json['labourRatePerSqFt'] as num?)?.toDouble() ??
          defaultLabourRatePerSqFt,
      puttyRatePerSqFt: (json['puttyRatePerSqFt'] as num?)?.toDouble() ??
          defaultPuttyRatePerSqFt,
      primerRatePerLiter: (json['primerRatePerLiter'] as num?)?.toDouble() ??
          defaultPrimerRatePerLiter,
      emulsionCoverageSqFt:
          (json['emulsionCoverageSqFt'] as num?)?.toDouble() ??
              defaultEmulsionCoverageSqFt,
      primerCoverageSqFt: (json['primerCoverageSqFt'] as num?)?.toDouble() ??
          defaultPrimerCoverageSqFt,
      distemperCoverageSqFt:
          (json['distemperCoverageSqFt'] as num?)?.toDouble() ??
              defaultDistemperCoverageSqFt,
      puttyEnabledByDefault: json['puttyEnabledByDefault'] as bool? ?? true,
    );
  }
}

/// Loads / saves brand rates and app settings in SharedPreferences.
class RatesService {
  static const String _brandRatesKey = 'painteasy_brand_rates';
  static const String _settingsKey = 'painteasy_settings';

  /// Brand rates: edited values if saved, otherwise the defaults.
  Future<Map<String, BrandRate>> loadBrandRates() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_brandRatesKey);
    if (raw == null || raw.isEmpty) {
      return Map<String, BrandRate>.from(defaultBrandRates);
    }
    try {
      final Map<String, dynamic> decoded =
          jsonDecode(raw) as Map<String, dynamic>;
      final Map<String, BrandRate> result =
          Map<String, BrandRate>.from(defaultBrandRates);
      for (final MapEntry<String, dynamic> entry in decoded.entries) {
        result[entry.key] =
            BrandRate.fromJson(entry.value as Map<String, dynamic>);
      }
      return result;
    } catch (_) {
      return Map<String, BrandRate>.from(defaultBrandRates);
    }
  }

  Future<void> saveBrandRates(Map<String, BrandRate> rates) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> jsonMap = <String, dynamic>{
      for (final MapEntry<String, BrandRate> e in rates.entries)
        e.key: e.value.toJson(),
    };
    await prefs.setString(_brandRatesKey, jsonEncode(jsonMap));
  }

  Future<void> resetBrandRates() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_brandRatesKey);
  }

  Future<AppSettings> loadSettings() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_settingsKey);
    if (raw == null || raw.isEmpty) {
      return AppSettings();
    }
    try {
      return AppSettings.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return AppSettings();
    }
  }

  Future<void> saveSettings(AppSettings settings) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  /// Coverage (sq ft / liter / coat) for a paint type, from settings.
  static double coverageForPaintType(AppSettings settings, String paintType) {
    return paintType == 'distemper'
        ? settings.distemperCoverageSqFt
        : settings.emulsionCoverageSqFt;
  }
}
