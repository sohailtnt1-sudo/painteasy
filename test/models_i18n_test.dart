import 'package:flutter_test/flutter_test.dart';
import 'package:painteasy/models/estimate.dart';
import 'package:painteasy/services/i18n.dart';
import 'package:painteasy/services/quotation_pdf.dart';
import 'package:painteasy/services/rates.dart';

void main() {
  group('models JSON round-trip', () {
    test('Room survives toJson/fromJson', () {
      final Room room = Room(
        name: 'Kitchen',
        length: 12,
        width: 10,
        height: 9,
        lengthInches: 6,
        widthInches: 3,
        includeCeiling: true,
        doors: 1,
        windows: 2,
      );
      final Room restored = Room.fromJson(room.toJson());
      expect(restored.name, 'Kitchen');
      expect(restored.length, 12);
      expect(restored.lengthInches, 6);
      expect(restored.includeCeiling, true);
      expect(restored.doors, 1);
      expect(restored.windows, 2);
    });

    test('Estimate survives toJson/fromJson', () {
      final Estimate estimate = Estimate(
        id: 'abc',
        title: 'House Paint',
        createdAt: DateTime(2026, 11, 23, 10, 30),
        unit: 'm',
        currency: 'USD',
        brand: 'Dulux',
        paintType: 'distemper',
        rooms: <Room>[
          Room(name: 'Bedroom', length: 4, width: 3, height: 3),
        ],
        labourRatePerSqFt: 30,
        puttyEnabled: false,
        painterName: 'Ahmed',
        customerName: 'Sara',
      );
      final Estimate restored = Estimate.fromJson(estimate.toJson());
      expect(restored.id, 'abc');
      expect(restored.unit, 'm');
      expect(restored.currency, 'USD');
      expect(restored.brand, 'Dulux');
      expect(restored.paintType, 'distemper');
      expect(restored.rooms.length, 1);
      expect(restored.rooms.first.name, 'Bedroom');
      expect(restored.puttyEnabled, false);
      expect(restored.painterName, 'Ahmed');
      expect(restored.customerName, 'Sara');
    });

    test('Estimate.fromJson tolerates missing fields', () {
      final Estimate restored = Estimate.fromJson(<String, dynamic>{});
      expect(restored.unit, 'ft');
      expect(restored.currency, 'PKR');
      expect(restored.rooms, isEmpty);
      expect(restored.labourRatePerSqFt, 25);
    });

    test('BrandRate survives toJson/fromJson', () {
      final BrandRate rate = BrandRate(
        brand: 'Berger',
        ratePerLiter: 900,
        coveragePerLiterSqFt: 100,
      );
      final BrandRate restored = BrandRate.fromJson(rate.toJson());
      expect(restored.brand, 'Berger');
      expect(restored.ratePerLiter, 900);
      expect(restored.coveragePerLiterSqFt, 100);
    });
  });

  group('i18n', () {
    test('English and Urdu have exactly the same keys', () {
      final Set<String> enKeys = localizedStrings['en']!.keys.toSet();
      final Set<String> urKeys = localizedStrings['ur']!.keys.toSet();
      expect(urKeys, enKeys);
    });

    test('no key translates to itself (empty translation)', () {
      for (final MapEntry<String, Map<String, String>> lang
          in localizedStrings.entries) {
        for (final MapEntry<String, String> entry in lang.value.entries) {
          expect(entry.value.trim(), isNotEmpty,
              reason: '${lang.key}.${entry.key} is empty');
        }
      }
    });

    test('translate falls back to English for unknown language', () {
      expect(
        LanguageProvider.translate('xx', 'save'),
        'Save',
      );
    });

    test('translate returns the key itself when missing everywhere', () {
      expect(
        LanguageProvider.translate('en', 'no_such_key_xyz'),
        'no_such_key_xyz',
      );
    });

    test('Urdu strings are in Urdu script', () {
      expect(
        LanguageProvider.translate('ur', 'save'),
        'محفوظ کریں',
      );
      expect(
        LanguageProvider.translate('ur', 'newEstimate'),
        'نیا تخمینہ',
      );
    });
  });

  group('rates defaults', () {
    test('all six brands have defaults', () {
      for (final String brand in supportedBrands) {
        expect(defaultBrandRates.containsKey(brand), true);
      }
      expect(defaultBrandRates['Berger']!.ratePerLiter, 900);
      expect(defaultBrandRates['Dulux']!.ratePerLiter, 1200);
    });

    test('coverage defaults match the plan', () {
      expect(defaultEmulsionCoverageSqFt, 100);
      expect(defaultPrimerCoverageSqFt, 120);
      expect(defaultDistemperCoverageSqFt, 110);
      expect(defaultLabourRatePerSqFt, 25);
      expect(defaultDoorAreaSqFt, 21);
      expect(defaultWindowAreaSqFt, 16);
    });

    test('distemper uses distemper coverage', () {
      final AppSettings settings = AppSettings();
      expect(
        RatesService.coverageForPaintType(settings, 'distemper'),
        110,
      );
      expect(
        RatesService.coverageForPaintType(settings, 'emulsion'),
        100,
      );
    });

    test('AppSettings survives toJson/fromJson', () {
      final AppSettings settings = AppSettings(
        currency: 'USD',
        defaultUnit: 'm',
        labourRatePerSqFt: 30,
      );
      final AppSettings restored =
          AppSettings.fromJson(settings.toJson());
      expect(restored.currency, 'USD');
      expect(restored.defaultUnit, 'm');
      expect(restored.labourRatePerSqFt, 30);
    });
  });

  group('quotation', () {
    test('formatDate renders dd/mm/yyyy', () {
      expect(formatDate(DateTime(2026, 11, 23)), '23/11/2026');
      expect(formatDate(DateTime(2026, 1, 5)), '05/01/2026');
    });

    test('formatMoney uses the symbol', () {
      expect(formatMoney(1234.56, 'Rs'), 'Rs 1235');
      expect(formatMoney(100, '\$'), '\$ 100');
    });
  });
}
