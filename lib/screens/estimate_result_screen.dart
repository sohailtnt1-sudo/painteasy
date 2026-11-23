// Result screen: material + labour + grand total on one clear screen,
// with the full breakdown (primer, paint, packs, putty, labour).

import 'package:material_ui/material_ui.dart';

import '../models/estimate.dart';
import '../services/calculator.dart';
import '../services/i18n.dart';
import '../services/quotation_pdf.dart';
import '../services/rates.dart';
import 'quotation_screen.dart';

class EstimateResultScreen extends StatefulWidget {
  const EstimateResultScreen({
    super.key,
    required this.languageProvider,
    required this.estimate,
  });

  final LanguageProvider languageProvider;
  final Estimate estimate;

  @override
  State<EstimateResultScreen> createState() => _EstimateResultScreenState();
}

class _EstimateResultScreenState extends State<EstimateResultScreen> {
  final RatesService _ratesService = RatesService();

  EstimateResult? _result;
  String _currencySymbol = 'Rs';
  String _paintTypeLabel = '';

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  Future<void> _calculate() async {
    final AppSettings settings = await _ratesService.loadSettings();
    final Map<String, BrandRate> rates = await _ratesService.loadBrandRates();
    final BrandRate? brandRate = rates[widget.estimate.brand];
    final double paintCoverage = widget.estimate.paintType == 'distemper'
        ? settings.distemperCoverageSqFt
        : (brandRate?.coveragePerLiterSqFt ?? defaultEmulsionCoverageSqFt);
    final EstimateResult result = calculateEstimate(
      widget.estimate,
      paintCoverageSqFt: paintCoverage,
      primerCoverageSqFt: settings.primerCoverageSqFt,
      paintRatePerLiter: brandRate?.ratePerLiter ?? 0,
      doorAreaSqFt: settings.doorAreaSqFt,
      windowAreaSqFt: settings.windowAreaSqFt,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _result = result;
      _currencySymbol =
          currencySymbols[widget.estimate.currency] ?? widget.estimate.currency;
      _paintTypeLabel = widget.estimate.paintType == 'distemper'
          ? widget.languageProvider.t('distemper')
          : widget.languageProvider.t('emulsion');
    });
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Expanded(child: Text(label)),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final LanguageProvider lang = widget.languageProvider;
    final Estimate estimate = widget.estimate;
    final EstimateResult? result = _result;
    return Scaffold(
      appBar: AppBar(title: Text(lang.t('totalCost'))),
      body: result == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                Text(
                  estimate.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  '${estimate.brand} • $_paintTypeLabel • ${estimate.rooms.length} ${lang.t('rooms').toLowerCase()}',
                ),
                const SizedBox(height: 16),
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: <Widget>[
                        Text(
                          lang.t('grandTotal'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          formatMoney(result.grandTotal, _currencySymbol),
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${lang.t('materialCost')}: ${formatMoney(result.materialCost, _currencySymbol)}'
                          ' • ${lang.t('labour')}: ${formatMoney(result.labourCostAmount, _currencySymbol)}',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  lang.t('breakdown'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                _row(
                  lang.t('paintableArea'),
                  '${result.paintableAreaSqFt.toStringAsFixed(0)} ${lang.t('sqFt')}',
                ),
                const Divider(),
                _row(
                  lang.t('primer'),
                  '${result.primerLitersNeeded.toStringAsFixed(1)} ${lang.t('liters')} — ${formatMoney(result.primerCost, _currencySymbol)}',
                ),
                _row(
                  lang.t('paint'),
                  '${result.paintLitersNeeded.toStringAsFixed(1)} ${lang.t('liters')} — ${formatMoney(result.paintCost, _currencySymbol)}',
                ),
                _row(
                  lang.t('packs'),
                  '${result.paintPacks.packs16L} x 16L + ${result.paintPacks.packs4L} x 4L',
                ),
                if (estimate.puttyEnabled)
                  _row(
                    lang.t('putty'),
                    formatMoney(result.puttyCostAmount, _currencySymbol),
                  ),
                _row(
                  lang.t('labour'),
                  formatMoney(result.labourCostAmount, _currencySymbol),
                ),
                const Divider(),
                _row(
                  lang.t('materialCost'),
                  formatMoney(result.materialCost, _currencySymbol),
                  bold: true,
                ),
                _row(
                  lang.t('grandTotal'),
                  formatMoney(result.grandTotal, _currencySymbol),
                  bold: true,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) => QuotationScreen(
                          languageProvider: lang,
                          estimate: estimate,
                          result: result,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.description),
                  label: Text(lang.t('makeQuotation')),
                ),
              ],
            ),
    );
  }
}
