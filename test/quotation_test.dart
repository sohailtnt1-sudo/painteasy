import 'package:flutter_test/flutter_test.dart';
import 'package:painteasy/models/estimate.dart';
import 'package:painteasy/services/calculator.dart';
import 'package:painteasy/services/i18n.dart';
import 'package:painteasy/services/quotation_pdf.dart';

Estimate _sampleEstimate() {
  return Estimate(
    id: 'q1',
    title: 'House Paint',
    createdAt: DateTime(2026, 11, 23),
    rooms: <Room>[
      Room(name: 'Living Room', length: 12, width: 10, height: 10),
    ],
    painterName: 'Ahmed',
    painterPhone: '03001234567',
    customerName: 'Sara',
  );
}

EstimateResult _sampleResult(Estimate estimate) {
  return calculateEstimate(
    estimate,
    paintCoverageSqFt: 100,
    primerCoverageSqFt: 120,
    paintRatePerLiter: 900,
    doorAreaSqFt: 21,
    windowAreaSqFt: 16,
  );
}

void main() {
  test('quotation PDF builds non-empty bytes', () async {
    final Estimate estimate = _sampleEstimate();
    final EstimateResult result = _sampleResult(estimate);

    final List<int> bytes = await buildQuotationPdf(
      estimate: estimate,
      result: result,
      currencySymbol: 'Rs',
      t: (String key) => LanguageProvider.translate('en', key),
    );
    expect(bytes.isNotEmpty, true);
    // PDF magic header.
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  test('quotation PDF builds non-empty bytes in Urdu (embedded font)',
      () async {
    // rootBundle needs the test binding to load the font asset.
    TestWidgetsFlutterBinding.ensureInitialized();
    final Estimate estimate = Estimate(
      id: 'q-ur',
      title: 'گھر کا پینٹ',
      createdAt: DateTime(2026, 11, 23),
      rooms: <Room>[
        Room(name: 'بیٹھک', length: 12, width: 10, height: 10),
      ],
      painterName: 'احمد',
      painterPhone: '03001234567',
      customerName: 'سارہ',
      brand: 'Berger',
      notes: 'دیواریں دو کوٹ میں پینٹ ہوں گی',
    );
    final EstimateResult result = _sampleResult(estimate);

    final List<int> bytes = await buildQuotationPdf(
      estimate: estimate,
      result: result,
      currencySymbol: 'Rs',
      t: (String key) => LanguageProvider.translate('ur', key),
      useUrduFont: true,
    );
    expect(bytes.isNotEmpty, true);
    // PDF magic header.
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  test('quotation text contains title, validity and grand total', () {
    final Estimate estimate = Estimate(
      id: 'q2',
      title: 'House Paint',
      createdAt: DateTime(2026, 11, 23),
      rooms: <Room>[
        Room(name: 'Living Room', length: 12, width: 10, height: 10),
      ],
      painterName: 'Ahmed',
      customerName: 'Sara',
    );
    final EstimateResult result = calculateEstimate(
      estimate,
      paintCoverageSqFt: 100,
      primerCoverageSqFt: 120,
      paintRatePerLiter: 900,
      doorAreaSqFt: 21,
      windowAreaSqFt: 16,
    );
    final String text = buildQuotationText(
      estimate: estimate,
      result: result,
      currencySymbol: 'Rs',
      t: (String key) => LanguageProvider.translate('en', key),
    );
    expect(text.contains('House Paint'), true);
    expect(text.contains('Ahmed'), true);
    expect(text.contains('Sara'), true);
    // Validity = created + 7 days = 30/11/2026.
    expect(text.contains('30/11/2026'), true);
    expect(text.contains('Grand total'), true);
  });
}
