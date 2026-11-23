// Quotation PDF (pdf package) + shareable text summary.
//
// Plain functions; the PDF is built in English labels via the [t]
// translator passed in so the same i18n map is reused.
//
// Urdu: the pdf package's built-in Helvetica has no Unicode support, so
// when [useUrduFont] is true the PDF is rendered with embedded
// Noto Naskh Arabic (assets/fonts/, OFL licensed) and laid out
// right-to-left. Latin text inside an Urdu quotation (brand names,
// "Rs", "16L", phone numbers, dates) falls back to Helvetica, because
// Noto Naskh Arabic has no Latin letter glyphs.
//
// Why the PDF splits Urdu text into directional runs: the pdf package's
// RTL handling reverses Latin runs inside an RTL paragraph ("Berger"
// comes out as "regreB", "Rs 1650" as "1650sR", dates get scrambled),
// so a mixed string is never handed to one RTL Text widget. Instead
// [_splitRuns] cuts it into pure Arabic-script and pure Latin runs,
// each rendered by its own Text widget with the matching direction,
// laid out right-to-left by a Wrap under an RTL Directionality.
// Pure runs render correctly; only mixed strings were broken.

import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/estimate.dart';
import 'calculator.dart';

String formatDate(DateTime date) {
  final String d = date.day.toString().padLeft(2, '0');
  final String m = date.month.toString().padLeft(2, '0');
  return '$d/$m/${date.year}';
}

String formatMoney(double amount, String symbol) {
  return '$symbol ${amount.toStringAsFixed(0)}';
}

/// Embedded Noto Naskh Arabic, loaded once and reused. Only loaded when
/// an Urdu quotation is built, so English PDFs stay exactly as before.
pw.Font? _urduRegular;
pw.Font? _urduBold;

Future<pw.Font> _urduRegularFont() async {
  _urduRegular ??= pw.Font.ttf(
    await rootBundle.load('assets/fonts/NotoNaskhArabic-Regular.ttf'),
  );
  return _urduRegular!;
}

Future<pw.Font> _urduBoldFont() async {
  _urduBold ??= pw.Font.ttf(
    await rootBundle.load('assets/fonts/NotoNaskhArabic-Bold.ttf'),
  );
  return _urduBold!;
}

/// True for code points in Arabic-script blocks (incl. Urdu letters and
/// Urdu digits) and the joiners ZWNJ/ZWJ used inside Urdu words.
bool _isArabicScript(int code) {
  return (code >= 0x0600 && code <= 0x06FF) ||
      (code >= 0x0750 && code <= 0x077F) ||
      (code >= 0x08A0 && code <= 0x08FF) ||
      (code >= 0xFB50 && code <= 0xFDFF) ||
      (code >= 0xFE70 && code <= 0xFEFF) ||
      code == 0x200C ||
      code == 0x200D;
}

/// One directional run of a mixed string.
class _Run {
  const _Run(this.text, this.arabic);

  final String text;

  /// True for an Arabic-script run, false for a Latin/digit run.
  final bool arabic;
}

/// Splits [text] into maximal runs of Arabic-script vs Latin/digit
/// characters. Spaces attach to the FOLLOWING run: a space before a
/// run of the other direction belongs with that run, so e.g. the space
/// in "(1 کوٹ)" stays between "1" and "کوٹ" instead of drifting to
/// the end of the parenthetical.
List<_Run> _splitRuns(String text) {
  final List<_Run> runs = <_Run>[];
  final StringBuffer current = StringBuffer();
  final StringBuffer pendingSpaces = StringBuffer();
  bool? currentArabic;

  void flush() {
    if (current.isEmpty) {
      return;
    }
    runs.add(_Run(current.toString(), currentArabic ?? false));
    current.clear();
    currentArabic = null;
  }

  for (int i = 0; i < text.length; i++) {
    final int code = text.codeUnitAt(i);
    if (code == 0x20) {
      // Space: hold it for the following run.
      pendingSpaces.writeCharCode(code);
      continue;
    }
    final bool isArabic = _isArabicScript(code);
    if (currentArabic == null) {
      currentArabic = isArabic;
    } else if (isArabic != currentArabic) {
      flush();
      currentArabic = isArabic;
    }
    if (pendingSpaces.isNotEmpty) {
      current.write(pendingSpaces.toString());
      pendingSpaces.clear();
    }
    current.writeCharCode(code);
  }
  // Trailing spaces attach to the last run.
  if (pendingSpaces.isNotEmpty) {
    current.write(pendingSpaces.toString());
  }
  flush();
  return runs;
}

/// Builds a one-page quotation PDF for [estimate] and its [result].
///
/// Pass [useUrduFont] true when the app language is Urdu so the PDF
/// renders Urdu script with the embedded Noto Naskh Arabic font.
/// English (the default) is unchanged and still uses Helvetica.
Future<Uint8List> buildQuotationPdf({
  required Estimate estimate,
  required EstimateResult result,
  required String currencySymbol,
  required String Function(String key) t,
  bool useUrduFont = false,
}) async {
  final DateTime validUntil = estimate.createdAt.add(const Duration(days: 7));
  final pw.Document doc = pw.Document();

  // Urdu: Noto Naskh Arabic + Helvetica fallback for Latin text.
  // English: no explicit font, i.e. the default Helvetica.
  final pw.Font? urduRegular =
      useUrduFont ? await _urduRegularFont() : null;
  final pw.Font? urduBold = useUrduFont ? await _urduBoldFont() : null;
  final pw.Font latinFallback = pw.Font.helvetica();
  final pw.Font latinFallbackBold = pw.Font.helveticaBold();

  pw.TextStyle urduStyle({double? fontSize, bool bold = false}) {
    return pw.TextStyle(
      fontSize: fontSize,
      font: bold ? urduBold : urduRegular,
      fontFallback: <pw.Font>[
        bold ? latinFallbackBold : latinFallback,
      ],
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
    );
  }

  pw.TextStyle englishStyle({double? fontSize, bool bold = false}) {
    return pw.TextStyle(
      fontSize: fontSize,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
    );
  }

  /// One piece of text. English: a single Text widget (unchanged).
  /// Urdu: the string split into directional runs, each its own Text
  /// widget with the matching direction and font, laid out
  /// right-to-left by a Wrap (see the file header comment).
  pw.Widget text(String content, {double? fontSize, bool bold = false}) {
    if (!useUrduFont) {
      return pw.Text(
        content,
        style: englishStyle(fontSize: fontSize, bold: bold),
      );
    }
    final List<_Run> runs = _splitRuns(content);
    if (runs.isEmpty) {
      return pw.SizedBox();
    }
    return pw.Wrap(
      children: <pw.Widget>[
        for (final _Run run in runs)
          pw.Text(
            run.text,
            textDirection:
                run.arabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
            style: run.arabic
                ? urduStyle(fontSize: fontSize, bold: bold)
                : pw.TextStyle(
                    fontSize: fontSize,
                    font: bold ? latinFallbackBold : latinFallback,
                    fontWeight:
                        bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                  ),
          ),
      ],
    );
  }

  pw.Widget row(String label, String value, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: <pw.Widget>[
          text(label, bold: bold),
          text(value, bold: bold),
        ],
      ),
    );
  }

  final pw.Widget content = pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: <pw.Widget>[
      text(
        t('quotationTitle'),
        fontSize: 24,
        bold: true,
      ),
      pw.SizedBox(height: 4),
      text(estimate.title, fontSize: 16),
      pw.SizedBox(height: 12),
      pw.Divider(),
      row(t('date'), formatDate(estimate.createdAt)),
      row(t('validUntil'), formatDate(validUntil)),
      row(t('painterName'), estimate.painterName),
      row(t('painterPhone'), estimate.painterPhone),
      row(t('customerName'), estimate.customerName),
      pw.SizedBox(height: 12),
      pw.Divider(),
      text(
        t('breakdown'),
        fontSize: 16,
        bold: true,
      ),
      pw.SizedBox(height: 6),
      row(t('paintableArea'),
          '${result.paintableAreaSqFt.toStringAsFixed(0)} ${t('sqFt')}'),
      row(t('brand'), estimate.brand),
      row(
        t('paintType'),
        estimate.paintType == 'distemper' ? t('distemper') : t('emulsion'),
      ),
      row(
        t('primer'),
        '${result.primerLitersNeeded.toStringAsFixed(1)} ${t('liters')} - ${formatMoney(result.primerCost, currencySymbol)}',
      ),
      row(
        t('paint'),
        '${result.paintLitersNeeded.toStringAsFixed(1)} ${t('liters')} - ${formatMoney(result.paintCost, currencySymbol)}',
      ),
      row(
        t('packs'),
        '${result.paintPacks.packs16L} x 16L + ${result.paintPacks.packs4L} x 4L',
      ),
      if (estimate.puttyEnabled)
        row(t('putty'), formatMoney(result.puttyCostAmount, currencySymbol)),
      row(t('labour'), formatMoney(result.labourCostAmount, currencySymbol)),
      pw.SizedBox(height: 8),
      pw.Divider(),
      row(
        t('materialCost'),
        formatMoney(result.materialCost, currencySymbol),
        bold: true,
      ),
      row(
        t('grandTotal'),
        formatMoney(result.grandTotal, currencySymbol),
        bold: true,
      ),
      pw.SizedBox(height: 12),
      text(
        t('validity'),
        fontSize: 12,
      ),
      if (estimate.notes.isNotEmpty) ...<pw.Widget>[
        pw.SizedBox(height: 8),
        text('${t('notes')}: ${estimate.notes}'),
      ],
    ],
  );

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        if (!useUrduFont) {
          return content;
        }
        return pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: content,
        );
      },
    ),
  );

  return doc.save();
}

/// Short text summary of the quotation, for WhatsApp / SMS sharing.
String buildQuotationText({
  required Estimate estimate,
  required EstimateResult result,
  required String currencySymbol,
  required String Function(String key) t,
}) {
  final DateTime validUntil = estimate.createdAt.add(const Duration(days: 7));
  final StringBuffer sb = StringBuffer();
  sb.writeln('${t('quotationTitle')} - ${estimate.title}');
  if (estimate.painterName.isNotEmpty) {
    sb.writeln('${t('painterName')}: ${estimate.painterName}');
  }
  if (estimate.customerName.isNotEmpty) {
    sb.writeln('${t('customerName')}: ${estimate.customerName}');
  }
  sb.writeln('${t('date')}: ${formatDate(estimate.createdAt)}');
  sb.writeln('${t('validUntil')}: ${formatDate(validUntil)}');
  sb.writeln(
      '${t('paintableArea')}: ${result.paintableAreaSqFt.toStringAsFixed(0)} ${t('sqFt')}');
  sb.writeln(
      '${t('paint')}: ${result.paintLitersNeeded.toStringAsFixed(1)} ${t('liters')} (${result.paintPacks.packs16L}x16L + ${result.paintPacks.packs4L}x4L)');
  sb.writeln(
      '${t('materialCost')}: ${formatMoney(result.materialCost, currencySymbol)}');
  sb.writeln(
      '${t('grandTotal')}: ${formatMoney(result.grandTotal, currencySymbol)}');
  return sb.toString();
}
