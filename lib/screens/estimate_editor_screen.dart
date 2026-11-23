// Estimate editor: title, unit, currency, brand, paint type, rooms,
// labour rate and putty. Saving goes to local storage; "View Result"
// saves first, then opens the result screen.

import 'package:material_ui/material_ui.dart';

import '../models/estimate.dart';
import '../services/i18n.dart';
import '../services/rates.dart';
import '../services/storage.dart';
import 'estimate_result_screen.dart';

class EstimateEditorScreen extends StatefulWidget {
  const EstimateEditorScreen({
    super.key,
    required this.languageProvider,
    this.existing,
  });

  final LanguageProvider languageProvider;
  final Estimate? existing;

  @override
  State<EstimateEditorScreen> createState() => _EstimateEditorScreenState();
}

class _EstimateEditorScreenState extends State<EstimateEditorScreen> {
  final EstimateStorage _storage = EstimateStorage();
  final RatesService _ratesService = RatesService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _labourController;
  late final TextEditingController _puttyRateController;
  late final TextEditingController _primerRateController;
  late final TextEditingController _painterNameController;
  late final TextEditingController _painterPhoneController;
  late final TextEditingController _customerNameController;
  late final TextEditingController _notesController;

  late String _unit;
  late String _currency;
  late String _brand;
  late String _paintType;
  late List<Room> _rooms;
  late bool _puttyEnabled;
  late String _id;
  late DateTime _createdAt;
  List<String> _brands = supportedBrands;

  @override
  void initState() {
    super.initState();
    final Estimate? existing = widget.existing;
    _id = existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString();
    _createdAt = existing?.createdAt ?? DateTime.now();
    _titleController = TextEditingController(text: existing?.title ?? '');
    _unit = existing?.unit ?? 'ft';
    _currency = existing?.currency ?? 'PKR';
    _brand = existing?.brand ?? 'Berger';
    _paintType = existing?.paintType ?? 'emulsion';
    _rooms = List<Room>.from(existing?.rooms ?? <Room>[]);
    _puttyEnabled = existing?.puttyEnabled ?? true;
    _labourController = TextEditingController(
      text: (existing?.labourRatePerSqFt ?? defaultLabourRatePerSqFt)
          .toStringAsFixed(0),
    );
    _puttyRateController = TextEditingController(
      text: (existing?.puttyRatePerSqFt ?? defaultPuttyRatePerSqFt)
          .toStringAsFixed(0),
    );
    _primerRateController = TextEditingController(
      text: (existing?.primerRatePerLiter ?? defaultPrimerRatePerLiter)
          .toStringAsFixed(0),
    );
    _painterNameController =
        TextEditingController(text: existing?.painterName ?? '');
    _painterPhoneController =
        TextEditingController(text: existing?.painterPhone ?? '');
    _customerNameController =
        TextEditingController(text: existing?.customerName ?? '');
    _notesController = TextEditingController(text: existing?.notes ?? '');
    _loadDefaults();
  }

  Future<void> _loadDefaults() async {
    final AppSettings settings = await _ratesService.loadSettings();
    final Map<String, BrandRate> rates = await _ratesService.loadBrandRates();
    if (!mounted) {
      return;
    }
    setState(() {
      _brands = rates.keys.toList();
      if (widget.existing == null) {
        _unit = settings.defaultUnit;
        _currency = settings.currency;
        _labourController.text =
            settings.labourRatePerSqFt.toStringAsFixed(0);
        _puttyRateController.text =
            settings.puttyRatePerSqFt.toStringAsFixed(0);
        _primerRateController.text =
            settings.primerRatePerLiter.toStringAsFixed(0);
        _puttyEnabled = settings.puttyEnabledByDefault;
      }
      if (!_brands.contains(_brand)) {
        _brand = _brands.isNotEmpty ? _brands.first : 'Berger';
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _labourController.dispose();
    _puttyRateController.dispose();
    _primerRateController.dispose();
    _painterNameController.dispose();
    _painterPhoneController.dispose();
    _customerNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double _parseDouble(String text, double fallback) {
    return double.tryParse(text.trim()) ?? fallback;
  }

  Estimate _buildEstimate() {
    return Estimate(
      id: _id,
      title: _titleController.text.trim().isEmpty
          ? widget.languageProvider.t('newEstimate')
          : _titleController.text.trim(),
      createdAt: _createdAt,
      unit: _unit,
      currency: _currency,
      brand: _brand,
      paintType: _paintType,
      rooms: _rooms,
      labourRatePerSqFt:
          _parseDouble(_labourController.text, defaultLabourRatePerSqFt),
      puttyEnabled: _puttyEnabled,
      puttyRatePerSqFt:
          _parseDouble(_puttyRateController.text, defaultPuttyRatePerSqFt),
      primerRatePerLiter:
          _parseDouble(_primerRateController.text, defaultPrimerRatePerLiter),
      painterName: _painterNameController.text.trim(),
      painterPhone: _painterPhoneController.text.trim(),
      customerName: _customerNameController.text.trim(),
      notes: _notesController.text.trim(),
    );
  }

  Future<void> _viewResult() async {
    if (_rooms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.languageProvider.t('addRoomFirst'))),
      );
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final Estimate estimate = _buildEstimate();
    await _storage.save(estimate);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(widget.languageProvider.t('estimateSaved'))),
    );
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => EstimateResultScreen(
          languageProvider: widget.languageProvider,
          estimate: estimate,
        ),
      ),
    );
  }

  Future<void> _addOrEditRoom([Room? room, int? index]) async {
    final Room? result = await showDialog<Room>(
      context: context,
      builder: (BuildContext context) => RoomDialog(
        languageProvider: widget.languageProvider,
        unit: _unit,
        room: room,
      ),
    );
    if (result == null) {
      return;
    }
    setState(() {
      if (index != null) {
        _rooms[index] = result;
      } else {
        _rooms.add(result);
      }
    });
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

  @override
  Widget build(BuildContext context) {
    final LanguageProvider lang = widget.languageProvider;
    final String areaUnit = _unit == 'm' ? lang.t('sqM') : lang.t('sqFt');
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing == null
              ? lang.t('newEstimate')
              : lang.t('edit'),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: _viewResult,
            child: Text(lang.t('viewResult')),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: lang.t('estimateTitle'),
                hintText: lang.t('enterTitle'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _unit,
                    decoration: InputDecoration(
                      labelText: lang.t('units'),
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
                        setState(() => _unit = value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _currency,
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
                        setState(() => _currency = value);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _brand,
                    decoration: InputDecoration(
                      labelText: lang.t('brand'),
                      border: const OutlineInputBorder(),
                    ),
                    items: _brands
                        .map(
                          (String b) => DropdownMenuItem<String>(
                            value: b,
                            child: Text(b),
                          ),
                        )
                        .toList(),
                    onChanged: (String? value) {
                      if (value != null) {
                        setState(() => _brand = value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _paintType,
                    decoration: InputDecoration(
                      labelText: lang.t('paintType'),
                      border: const OutlineInputBorder(),
                    ),
                    items: <DropdownMenuItem<String>>[
                      DropdownMenuItem<String>(
                        value: 'emulsion',
                        child: Text(lang.t('emulsion')),
                      ),
                      DropdownMenuItem<String>(
                        value: 'distemper',
                        child: Text(lang.t('distemper')),
                      ),
                    ],
                    onChanged: (String? value) {
                      if (value != null) {
                        setState(() => _paintType = value);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  lang.t('rooms'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton.icon(
                  onPressed: () => _addOrEditRoom(),
                  icon: const Icon(Icons.add),
                  label: Text(lang.t('addRoom')),
                ),
              ],
            ),
            if (_rooms.isEmpty)
              Text(lang.t('noRoomsYet'))
            else
              ..._rooms.asMap().entries.map((MapEntry<int, Room> entry) {
                final int i = entry.key;
                final Room room = entry.value;
                return Card(
                  child: ListTile(
                    title: Text(room.name),
                    subtitle: Text(
                      '${room.length} x ${room.width} x ${room.height} '
                      '${_unit == 'm' ? 'm' : 'ft'}'
                      ' • ${room.doors} ${lang.t('doors').toLowerCase()}'
                      ' • ${room.windows} ${lang.t('windows').toLowerCase()}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        IconButton(
                          icon: const Icon(Icons.edit),
                          tooltip: lang.t('edit'),
                          onPressed: () => _addOrEditRoom(room, i),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          tooltip: lang.t('delete'),
                          onPressed: () {
                            setState(() => _rooms.removeAt(i));
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 20),
            Text(
              lang.t('labour'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _numberField(
              controller: _labourController,
              label: '${lang.t('labourRate')} ($areaUnit)',
              suffix: lang.t('perSqFt'),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: Text(lang.t('puttyToggle')),
              value: _puttyEnabled,
              onChanged: (bool value) {
                setState(() => _puttyEnabled = value);
              },
            ),
            if (_puttyEnabled)
              _numberField(
                controller: _puttyRateController,
                label: '${lang.t('puttyRate')} ($areaUnit)',
                suffix: lang.t('perSqFt'),
              ),
            const SizedBox(height: 12),
            _numberField(
              controller: _primerRateController,
              label: lang.t('primerRate'),
              suffix: lang.t('perLiter'),
            ),
            const SizedBox(height: 20),
            Text(
              lang.t('painterDetails'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _painterNameController,
              decoration: InputDecoration(
                labelText: lang.t('painterName'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _painterPhoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: lang.t('painterPhone'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _customerNameController,
              decoration: InputDecoration(
                labelText: lang.t('customerName'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: lang.t('notes'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _viewResult,
              child: Text(lang.t('viewResult')),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

/// Dialog for adding / editing one room.
class RoomDialog extends StatefulWidget {
  const RoomDialog({
    super.key,
    required this.languageProvider,
    required this.unit,
    this.room,
  });

  final LanguageProvider languageProvider;
  final String unit;
  final Room? room;

  @override
  State<RoomDialog> createState() => _RoomDialogState();
}

class _RoomDialogState extends State<RoomDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _lengthController;
  late final TextEditingController _lengthInchesController;
  late final TextEditingController _widthController;
  late final TextEditingController _widthInchesController;
  late final TextEditingController _heightController;
  late final TextEditingController _doorsController;
  late final TextEditingController _windowsController;
  late bool _includeCeiling;

  @override
  void initState() {
    super.initState();
    final Room? room = widget.room;
    _nameController = TextEditingController(text: room?.name ?? '');
    _lengthController = TextEditingController(
      text: room == null ? '' : room.length.toStringAsFixed(0),
    );
    _lengthInchesController = TextEditingController(
      text: (room?.lengthInches ?? 0).toString(),
    );
    _widthController = TextEditingController(
      text: room == null ? '' : room.width.toStringAsFixed(0),
    );
    _widthInchesController = TextEditingController(
      text: (room?.widthInches ?? 0).toString(),
    );
    _heightController = TextEditingController(
      text: room == null ? '' : room.height.toStringAsFixed(0),
    );
    _doorsController = TextEditingController(
      text: (room?.doors ?? 0).toString(),
    );
    _windowsController = TextEditingController(
      text: (room?.windows ?? 0).toString(),
    );
    _includeCeiling = room?.includeCeiling ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lengthController.dispose();
    _lengthInchesController.dispose();
    _widthController.dispose();
    _widthInchesController.dispose();
    _heightController.dispose();
    _doorsController.dispose();
    _windowsController.dispose();
    super.dispose();
  }

  String? _numberValidator(String? value, {bool required = true}) {
    final LanguageProvider lang = widget.languageProvider;
    if (value == null || value.trim().isEmpty) {
      return required ? lang.t('required') : null;
    }
    if (double.tryParse(value.trim()) == null) {
      return lang.t('invalidNumber');
    }
    return null;
  }

  Widget _dimensionField({
    required TextEditingController controller,
    required String label,
  }) {
    return Expanded(
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (String? v) => _numberValidator(v),
      ),
    );
  }

  Widget _inchesField(TextEditingController controller) {
    return SizedBox(
      width: 72,
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: widget.languageProvider.t('inches'),
          border: const OutlineInputBorder(),
        ),
        validator: (String? v) {
          final int? parsed = int.tryParse(v?.trim() ?? '');
          if (parsed == null || parsed < 0 || parsed > 11) {
            return '0-11';
          }
          return null;
        },
      ),
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final String name = _nameController.text.trim().isEmpty
        ? widget.languageProvider.t('room')
        : _nameController.text.trim();
    Navigator.of(context).pop(
      Room(
        name: name,
        length: double.parse(_lengthController.text.trim()),
        width: double.parse(_widthController.text.trim()),
        height: double.parse(_heightController.text.trim()),
        lengthInches: widget.unit == 'ft'
            ? int.parse(_lengthInchesController.text.trim())
            : 0,
        widthInches: widget.unit == 'ft'
            ? int.parse(_widthInchesController.text.trim())
            : 0,
        includeCeiling: _includeCeiling,
        doors: double.parse(_doorsController.text.trim()).round(),
        windows: double.parse(_windowsController.text.trim()).round(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final LanguageProvider lang = widget.languageProvider;
    final bool isFeet = widget.unit == 'ft';
    final String dimUnit = isFeet ? 'ft' : 'm';
    return AlertDialog(
      title: Text(widget.room == null ? lang.t('addRoom') : lang.t('editRoom')),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: lang.t('roomName'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  _dimensionField(
                    controller: _lengthController,
                    label: '${lang.t('length')} ($dimUnit)',
                  ),
                  if (isFeet) ...<Widget>[
                    const SizedBox(width: 8),
                    _inchesField(_lengthInchesController),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  _dimensionField(
                    controller: _widthController,
                    label: '${lang.t('width')} ($dimUnit)',
                  ),
                  if (isFeet) ...<Widget>[
                    const SizedBox(width: 8),
                    _inchesField(_widthInchesController),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              _dimensionField(
                controller: _heightController,
                label: '${lang.t('height')} ($dimUnit)',
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  _dimensionField(
                    controller: _doorsController,
                    label: lang.t('doors'),
                  ),
                  const SizedBox(width: 8),
                  _dimensionField(
                    controller: _windowsController,
                    label: lang.t('windows'),
                  ),
                ],
              ),
              CheckboxListTile(
                title: Text(lang.t('includeCeiling')),
                value: _includeCeiling,
                onChanged: (bool? value) {
                  setState(() => _includeCeiling = value ?? false);
                },
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(lang.t('cancel')),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(lang.t('saveRoom')),
        ),
      ],
    );
  }
}
