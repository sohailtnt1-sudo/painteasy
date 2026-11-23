// Home screen: list of saved estimates (newest first).

import 'package:material_ui/material_ui.dart';

import '../models/estimate.dart';
import '../services/calculator.dart';
import '../services/i18n.dart';
import '../services/quotation_pdf.dart';
import '../services/rates.dart';
import '../services/storage.dart';
import 'estimate_editor_screen.dart';
import 'estimate_result_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.languageProvider});

  final LanguageProvider languageProvider;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final EstimateStorage _storage = EstimateStorage();
  final RatesService _ratesService = RatesService();

  List<Estimate> _estimates = <Estimate>[];
  Map<String, BrandRate> _brandRates = <String, BrandRate>{};
  AppSettings _settings = AppSettings();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final List<Estimate> estimates = await _storage.loadAll();
    final Map<String, BrandRate> rates = await _ratesService.loadBrandRates();
    final AppSettings settings = await _ratesService.loadSettings();
    if (!mounted) {
      return;
    }
    setState(() {
      _estimates = estimates;
      _brandRates = rates;
      _settings = settings;
      _loading = false;
    });
  }

  String _currencySymbol(String code) {
    return currencySymbols[code] ?? code;
  }

  double _totalFor(Estimate estimate) {
    final BrandRate? brandRate = _brandRates[estimate.brand];
    final double paintRate = brandRate?.ratePerLiter ?? 0;
    final double paintCoverage =
        brandRate?.coveragePerLiterSqFt ?? defaultEmulsionCoverageSqFt;
    final double coverage = estimate.paintType == 'distemper'
        ? _settings.distemperCoverageSqFt
        : paintCoverage;
    final EstimateResult result = calculateEstimate(
      estimate,
      paintCoverageSqFt: coverage,
      primerCoverageSqFt: _settings.primerCoverageSqFt,
      paintRatePerLiter: paintRate,
      doorAreaSqFt: _settings.doorAreaSqFt,
      windowAreaSqFt: _settings.windowAreaSqFt,
    );
    return result.grandTotal;
  }

  Future<void> _openEditor([Estimate? existing]) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => EstimateEditorScreen(
          languageProvider: widget.languageProvider,
          existing: existing,
        ),
      ),
    );
    await _load();
  }

  Future<void> _openResult(Estimate estimate) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => EstimateResultScreen(
          languageProvider: widget.languageProvider,
          estimate: estimate,
        ),
      ),
    );
    await _load();
  }

  Future<void> _confirmDelete(Estimate estimate) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final LanguageProvider lang = widget.languageProvider;
        return AlertDialog(
          title: Text(lang.t('confirmDelete')),
          content: Text(lang.t('confirmDeleteMsg')),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(lang.t('cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(lang.t('yesDelete')),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      await _storage.delete(estimate.id);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final LanguageProvider lang = widget.languageProvider;
    return Scaffold(
      appBar: AppBar(
        title: Text(lang.t('appTitle')),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: lang.t('settings'),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => SettingsScreen(
                    languageProvider: widget.languageProvider,
                  ),
                ),
              );
              await _load();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _estimates.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          lang.t('noEstimates'),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(lang.t('noEstimatesHint')),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _estimates.length,
                  itemBuilder: (BuildContext context, int index) {
                    final Estimate estimate = _estimates[index];
                    final String symbol =
                        _currencySymbol(estimate.currency);
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        title: Text(estimate.title),
                        subtitle: Text(
                          '${formatDate(estimate.createdAt)} • ${estimate.rooms.length} ${lang.t('rooms').toLowerCase()} • ${estimate.brand}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              formatMoney(_totalFor(estimate), symbol),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (String value) async {
                                if (value == 'edit') {
                                  await _openEditor(estimate);
                                } else if (value == 'duplicate') {
                                  await _storage.duplicate(estimate);
                                  await _load();
                                } else if (value == 'delete') {
                                  await _confirmDelete(estimate);
                                }
                              },
                              itemBuilder: (BuildContext context) {
                                return <PopupMenuEntry<String>>[
                                  PopupMenuItem<String>(
                                    value: 'edit',
                                    child: Text(lang.t('edit')),
                                  ),
                                  PopupMenuItem<String>(
                                    value: 'duplicate',
                                    child: Text(lang.t('duplicate')),
                                  ),
                                  PopupMenuItem<String>(
                                    value: 'delete',
                                    child: Text(lang.t('delete')),
                                  ),
                                ];
                              },
                            ),
                          ],
                        ),
                        onTap: () => _openResult(estimate),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: Text(lang.t('newEstimate')),
      ),
    );
  }
}
