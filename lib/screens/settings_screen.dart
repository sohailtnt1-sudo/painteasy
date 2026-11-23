// Settings: language, currency, default unit, standard door/window
// sizes, default labour / putty / primer rates, coverage values and
// per-brand rates. Everything is stored locally (SharedPreferences).

import 'package:material_ui/material_ui.dart';

import '../models/estimate.dart';
import '../services/i18n.dart';
import '../services/rates.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.languageProvider});

  final LanguageProvider languageProvider;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final RatesService _ratesService = RatesService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  AppSettings _settings = AppSettings();
  Map<String, BrandRate> _brandRates =
      Map<String, BrandRate>.from(defaultBrandRates);
  bool _loading = true;

  late final TextEditingController _doorController;
  late final TextEditingController _windowController;
  late final TextEditingController _labourController;
  late final TextEditingController _puttyController;
  late final TextEditingController _primerRateController;
  late final TextEditingController _emulsionCoverageController;
  late final TextEditingController _primerCoverageController;
  late final TextEditingController _distemperCoverageController;
  final Map<String, TextEditingController> _brandRateControllers =
      <String, TextEditingController>{};
  final Map<String, TextEditingController> _brandCoverageControllers =
      <String, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    _doorController = TextEditingController();
    _windowController = TextEditingController();
    _labourController = TextEditingController();
    _puttyController = TextEditingController();
    _primerRateController = TextEditingController();
    _emulsionCoverageController = TextEditingController();
    _primerCoverageController = TextEditingController();
    _distemperCoverageController = TextEditingController();
    _load();
  }

  Future<void> _load() async {
    final AppSettings settings = await _ratesService.loadSettings();
    final Map<String, BrandRate> rates = await _ratesService.loadBrandRates();
    if (!mounted) {
      return;
    }
    setState(() {
      _settings = settings;
      _brandRates = rates;
      _doorController.text = settings.doorAreaSqFt.toStringAsFixed(0);
      _windowController.text = settings.windowAreaSqFt.toStringAsFixed(0);
      _labourController.text = settings.labourRatePerSqFt.toStringAsFixed(0);
      _puttyController.text = settings.puttyRatePerSqFt.toStringAsFixed(0);
      _primerRateController.text =
          settings.primerRatePerLiter.toStringAsFixed(0);
      _emulsionCoverageController.text =
          settings.emulsionCoverageSqFt.toStringAsFixed(0);
      _primerCoverageController.text =
          settings.primerCoverageSqFt.toStringAsFixed(0);
      _distemperCoverageController.text =
          settings.distemperCoverageSqFt.toStringAsFixed(0);
      for (final MapEntry<String, BrandRate> entry in rates.entries) {
        _brandRateControllers[entry.key] ??=
            TextEditingController(text: entry.value.ratePerLiter.toStringAsFixed(0));
        _brandCoverageControllers[entry.key] ??= TextEditingController(
          text: entry.value.coveragePerLiterSqFt.toStringAsFixed(0),
        );
      }
      _loading = false;
    });
  }

  @override
  void dispose() {
    _doorController.dispose();
    _windowController.dispose();
    _labourController.dispose();
    _puttyController.dispose();
    _primerRateController.dispose();
    _emulsionCoverageController.dispose();
    _primerCoverageController.dispose();
    _distemperCoverageController.dispose();
    for (final TextEditingController c in _brandRateControllers.values) {
      c.dispose();
    }
    for (final TextEditingController c in _brandCoverageControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  double _parse(String text, double fallback) {
    return double.tryParse(text.trim()) ?? fallback;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final AppSettings settings = _settings.copyWith(
      doorAreaSqFt: _parse(_doorController.text, defaultDoorAreaSqFt),
      windowAreaSqFt: _parse(_windowController.text, defaultWindowAreaSqFt),
      labourRatePerSqFt:
          _parse(_labourController.text, defaultLabourRatePerSqFt),
      puttyRatePerSqFt: _parse(_puttyController.text, defaultPuttyRatePerSqFt),
      primerRatePerLiter:
          _parse(_primerRateController.text, defaultPrimerRatePerLiter),
      emulsionCoverageSqFt: _parse(
        _emulsionCoverageController.text,
        defaultEmulsionCoverageSqFt,
      ),
      primerCoverageSqFt:
          _parse(_primerCoverageController.text, defaultPrimerCoverageSqFt),
      distemperCoverageSqFt: _parse(
        _distemperCoverageController.text,
        defaultDistemperCoverageSqFt,
      ),
    );
    final Map<String, BrandRate> rates = <String, BrandRate>{};
    for (final MapEntry<String, BrandRate> entry in _brandRates.entries) {
      final double rate = _parse(
        _brandRateControllers[entry.key]?.text ?? '',
        entry.value.ratePerLiter,
      );
      final double coverage = _parse(
        _brandCoverageControllers[entry.key]?.text ?? '',
        entry.value.coveragePerLiterSqFt,
      );
      rates[entry.key] = entry.value.copyWith(
        ratePerLiter: rate,
        coveragePerLiterSqFt: coverage,
      );
    }
    await _ratesService.saveSettings(settings);
    await _ratesService.saveBrandRates(rates);
    if (!mounted) {
      return;
    }
    setState(() => _settings = settings);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(widget.languageProvider.t('settingsSaved'))),
    );
  }

  Future<void> _resetRates() async {
    await _ratesService.resetBrandRates();
    await _load();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(widget.languageProvider.t('ratesReset'))),
    );
  }

  Widget _numberField({
    required TextEditingController controller,
    required String label,
    String? suffix,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        border: const OutlineInputBorder(),
      ),
      validator: (String? value) {
        if (value == null ||
            value.trim().isEmpty ||
            double.tryParse(value.trim()) == null) {
          return widget.languageProvider.t('invalidNumber');
        }
        return null;
      },
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final LanguageProvider lang = widget.languageProvider;
    return Scaffold(
      appBar: AppBar(
        title: Text(lang.t('settings')),
        actions: <Widget>[
          TextButton(
            onPressed: _save,
            child: Text(lang.t('save')),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: <Widget>[
                  DropdownButtonFormField<String>(
                    key: ValueKey<String>(lang.language),
                    initialValue: lang.language,
                    decoration: InputDecoration(
                      labelText: lang.t('language'),
                      border: const OutlineInputBorder(),
                    ),
                    items: <DropdownMenuItem<String>>[
                      DropdownMenuItem<String>(
                        value: 'en',
                        child: Text(lang.t('english')),
                      ),
                      DropdownMenuItem<String>(
                        value: 'ur',
                        child: Text(lang.t('urdu')),
                      ),
                    ],
                    onChanged: (String? value) async {
                      if (value != null) {
                        await lang.setLanguage(value);
                        setState(() {});
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _settings.currency,
                    decoration: InputDecoration(
                      labelText: lang.t('currency'),
                      border: const OutlineInputBorder(),
                    ),
                    items: supportedCurrencies
                        .map(
                          (String c) => DropdownMenuItem<String>(
                            value: c,
                            child: Text(c),
                          ),
                        )
                        .toList(),
                    onChanged: (String? value) {
                      if (value != null) {
                        setState(() {
                          _settings = _settings.copyWith(currency: value);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lang.t('currencyNote'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _settings.defaultUnit,
                    decoration: InputDecoration(
                      labelText: lang.t('defaultUnit'),
                      border: const OutlineInputBorder(),
                    ),
                    items: <DropdownMenuItem<String>>[
                      DropdownMenuItem<String>(
                        value: 'ft',
                        child: Text(lang.t('feet')),
                      ),
                      DropdownMenuItem<String>(
                        value: 'm',
                        child: Text(lang.t('meters')),
                      ),
                    ],
                    onChanged: (String? value) {
                      if (value != null) {
                        setState(() {
                          _settings = _settings.copyWith(defaultUnit: value);
                        });
                      }
                    },
                  ),
                  _sectionTitle(lang.t('rooms')),
                  _numberField(
                    controller: _doorController,
                    label: '${lang.t('doorSize')} (${lang.t('sqFt')})',
                  ),
                  const SizedBox(height: 12),
                  _numberField(
                    controller: _windowController,
                    label: '${lang.t('windowSize')} (${lang.t('sqFt')})',
                  ),
                  _sectionTitle(lang.t('labour')),
                  _numberField(
                    controller: _labourController,
                    label: lang.t('labourRate'),
                    suffix: lang.t('perSqFt'),
                  ),
                  const SizedBox(height: 12),
                  _numberField(
                    controller: _puttyController,
                    label: lang.t('puttyRate'),
                    suffix: lang.t('perSqFt'),
                  ),
                  const SizedBox(height: 12),
                  _numberField(
                    controller: _primerRateController,
                    label: lang.t('primerRate'),
                    suffix: lang.t('perLiter'),
                  ),
                  _sectionTitle(lang.t('brandRates')),
                  Card(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(lang.t('ratesNote')),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _numberField(
                    controller: _emulsionCoverageController,
                    label: lang.t('emulsionCoverage'),
                    suffix: lang.t('sqFtPerLiter'),
                  ),
                  const SizedBox(height: 12),
                  _numberField(
                    controller: _primerCoverageController,
                    label: lang.t('primerCoverage'),
                    suffix: lang.t('sqFtPerLiter'),
                  ),
                  const SizedBox(height: 12),
                  _numberField(
                    controller: _distemperCoverageController,
                    label: lang.t('distemperCoverage'),
                    suffix: lang.t('sqFtPerLiter'),
                  ),
                  const SizedBox(height: 12),
                  ..._brandRates.entries.map(
                    (MapEntry<String, BrandRate> entry) {
                      final TextEditingController rateController =
                          _brandRateControllers[entry.key]!;
                      final TextEditingController coverageController =
                          _brandCoverageControllers[entry.key]!;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: <Widget>[
                            SizedBox(
                              width: 96,
                              child: Text(
                                entry.key,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(
                              child: _numberField(
                                controller: rateController,
                                label: lang.t('ratePerLiter'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _numberField(
                                controller: coverageController,
                                label: lang.t('coveragePerLiter'),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  TextButton(
                    onPressed: _resetRates,
                    child: Text(lang.t('resetRates')),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _save,
                    child: Text(lang.t('save')),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
}
