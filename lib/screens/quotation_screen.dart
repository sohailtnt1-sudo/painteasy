// Quotation screen: painter/customer details, 7-day validity,
// share as PDF (WhatsApp-ready via share_plus) or as text.

import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

import '../models/estimate.dart';
import '../services/calculator.dart';
import '../services/i18n.dart';
import '../services/quotation_pdf.dart';
import '../services/rates.dart';
import '../services/storage.dart';

class QuotationScreen extends StatefulWidget {
  const QuotationScreen({
    super.key,
    required this.languageProvider,
    required this.estimate,
    required this.result,
  });

  final LanguageProvider languageProvider;
  final Estimate estimate;
  final EstimateResult result;

  @override
  State<QuotationScreen> createState() => _QuotationScreenState();
}

class _QuotationScreenState extends State<QuotationScreen> {
  final EstimateStorage _storage = EstimateStorage();
  late final TextEditingController _painterNameController;
  late final TextEditingController _painterPhoneController;
  late final TextEditingController _customerNameController;
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    _painterNameController =
        TextEditingController(text: widget.estimate.painterName);
    _painterPhoneController =
        TextEditingController(text: widget.estimate.painterPhone);
    _customerNameController =
        TextEditingController(text: widget.estimate.customerName);
  }

  @override
  void dispose() {
    _painterNameController.dispose();
    _painterPhoneController.dispose();
    _customerNameController.dispose();
    super.dispose();
  }

  Estimate _currentEstimate() {
    return widget.estimate.copyWith(
      painterName: _painterNameController.text.trim(),
      painterPhone: _painterPhoneController.text.trim(),
      customerName: _customerNameController.text.trim(),
    );
  }

  Future<void> _saveDetails() async {
    await _storage.save(_currentEstimate());
  }

  Future<void> _sharePdf() async {
    setState(() => _sharing = true);
    try {
      await _saveDetails();
      final LanguageProvider lang = widget.languageProvider;
      final Estimate estimate = _currentEstimate();
      final String symbol =
          currencySymbols[estimate.currency] ?? estimate.currency;
      final Uint8List bytes = await buildQuotationPdf(
        estimate: estimate,
        result: widget.result,
        currencySymbol: symbol,
        t: lang.t,
        useUrduFont: lang.isUrdu,
      );
      await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[
            XFile.fromData(
              bytes,
              name: 'quotation-${estimate.id}.pdf',
              mimeType: 'application/pdf',
            ),
          ],
          text: buildQuotationText(
            estimate: estimate,
            result: widget.result,
            currencySymbol: symbol,
            t: lang.t,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _sharing = false);
      }
    }
  }

  Future<void> _shareText() async {
    await _saveDetails();
    final LanguageProvider lang = widget.languageProvider;
    final Estimate estimate = _currentEstimate();
    final String symbol =
        currencySymbols[estimate.currency] ?? estimate.currency;
    await SharePlus.instance.share(
      ShareParams(
        text: buildQuotationText(
          estimate: estimate,
          result: widget.result,
          currencySymbol: symbol,
          t: lang.t,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final LanguageProvider lang = widget.languageProvider;
    final Estimate estimate = widget.estimate;
    final DateTime validUntil = estimate.createdAt.add(const Duration(days: 7));
    final String symbol =
        currencySymbols[estimate.currency] ?? estimate.currency;
    return Scaffold(
      appBar: AppBar(title: Text(lang.t('quotation'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(
            estimate.title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text('${lang.t('date')}: ${formatDate(estimate.createdAt)}'),
          Text('${lang.t('validUntil')}: ${formatDate(validUntil)}'),
          Text(
            lang.t('validity'),
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${lang.t('grandTotal')}: '
            '${formatMoney(widget.result.grandTotal, symbol)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 20),
          Text(
            lang.t('painterDetails'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _painterNameController,
            decoration: InputDecoration(
              labelText: lang.t('painterName'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _painterPhoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: lang.t('painterPhone'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            lang.t('customerDetails'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _customerNameController,
            decoration: InputDecoration(
              labelText: lang.t('customerName'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _sharing ? null : _sharePdf,
            icon: const Icon(Icons.picture_as_pdf),
            label: Text(lang.t('sharePdf')),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _sharing ? null : _shareText,
            icon: const Icon(Icons.share),
            label: Text(lang.t('shareText')),
          ),
        ],
      ),
    );
  }
}
