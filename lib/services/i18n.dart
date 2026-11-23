// Language system for PaintEasy.
//
// Adding a language later = one new entry in [localizedStrings].
// All user-facing strings go through [LanguageProvider.t] — no hardcoded
// UI strings outside these maps.

import 'dart:ui' show TextDirection;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _languageKey = 'painteasy_language';

/// language code -> key -> string.
const Map<String, Map<String, String>> localizedStrings =
    <String, Map<String, String>>{
  'en': <String, String>{
    'appTitle': 'PaintEasy',
    'appTagline': 'Paint estimate & quotation, made simple',
    'savedEstimates': 'Saved Estimates',
    'noEstimates': 'No estimates yet',
    'noEstimatesHint': 'Tap + to make your first paint estimate.',
    'newEstimate': 'New Estimate',
    'edit': 'Edit',
    'duplicate': 'Duplicate',
    'delete': 'Delete',
    'confirmDelete': 'Delete estimate?',
    'confirmDeleteMsg': 'This estimate will be permanently deleted.',
    'cancel': 'Cancel',
    'yesDelete': 'Delete',
    'save': 'Save',
    'settings': 'Settings',
    'language': 'Language',
    'english': 'English',
    'urdu': 'Urdu',
    'currency': 'Currency',
    'currencyNote':
        'Rates are entered in the selected currency. No live conversion.',
    'units': 'Units',
    'feet': 'Feet + Inch',
    'meters': 'Meter',
    'defaultUnit': 'Default unit',
    'doorSize': 'Standard door size',
    'windowSize': 'Standard window size',
    'labourRate': 'Labour rate',
    'puttyRate': 'Putty rate',
    'primerRate': 'Primer rate',
    'emulsionCoverage': 'Emulsion coverage',
    'primerCoverage': 'Primer coverage',
    'distemperCoverage': 'Distemper coverage',
    'perSqFt': 'per sq ft',
    'perLiter': 'per liter',
    'sqFtPerLiter': 'sq ft / liter / coat',
    'ratesNote':
        'These are starting values only. Please confirm rates and coverage with a real painter before relying on them.',
    'brandRates': 'Brand rates',
    'ratePerLiter': 'Rate per liter',
    'coveragePerLiter': 'Coverage (sq ft / L)',
    'resetRates': 'Reset rates to defaults',
    'ratesReset': 'Rates reset to defaults',
    'settingsSaved': 'Settings saved',
    'estimateTitle': 'Estimate title',
    'brand': 'Paint brand',
    'paintType': 'Paint type',
    'emulsion': 'Emulsion',
    'distemper': 'Distemper',
    'rooms': 'Rooms',
    'addRoom': 'Add Room',
    'roomName': 'Room name',
    'length': 'Length',
    'width': 'Width',
    'height': 'Height',
    'inches': 'in',
    'includeCeiling': 'Include ceiling',
    'doors': 'Doors',
    'windows': 'Windows',
    'wallArea': 'Wall area',
    'ceilingArea': 'Ceiling area',
    'paintableArea': 'Paintable area',
    'primer': 'Primer (1 coat)',
    'paint': 'Paint (2 coats)',
    'putty': 'Putty',
    'labour': 'Labour',
    'materialCost': 'Material cost',
    'totalCost': 'Total estimate',
    'grandTotal': 'Grand total',
    'liters': 'liters',
    'packs': 'Packs',
    'pack16': '16L packs',
    'pack4': '4L packs',
    'viewResult': 'View Result',
    'calculate': 'Calculate',
    'quotation': 'Quotation',
    'validity': 'Valid for 7 days',
    'validUntil': 'Valid until',
    'sharePdf': 'Share as PDF',
    'shareText': 'Share as text',
    'share': 'Share',
    'date': 'Date',
    'notes': 'Notes',
    'painterDetails': 'Painter details',
    'customerDetails': 'Customer details',
    'painterName': 'Painter name',
    'painterPhone': 'Painter phone',
    'customerName': 'Customer name',
    'required': 'Required',
    'invalidNumber': 'Enter a valid number',
    'addRoomFirst': 'Add at least one room first.',
    'puttyToggle': 'Include putty',
    'quotationTitle': 'Paint Quotation',
    'createdOn': 'Created',
    'estimateSaved': 'Estimate saved',
    'room': 'Room',
    'livingRoom': 'Living Room',
    'bedroom': 'Bedroom',
    'kitchen': 'Kitchen',
    'bathroom': 'Bathroom',
    'editRoom': 'Edit Room',
    'saveRoom': 'Save Room',
    'sqFt': 'sq ft',
    'sqM': 'sq m',
    'totalLiters': 'Total liters',
    'cost': 'Cost',
    'breakdown': 'Breakdown',
    'makeQuotation': 'Make Quotation',
    'enterTitle': 'Enter a title, e.g. House Paint',
    'noRoomsYet': 'No rooms added yet.',
    'areaUnit': 'Area',
  },
  'ur': <String, String>{
    'appTitle': 'پینٹ ایزی',
    'appTagline': 'پینٹ کا تخمینہ اور کوٹیشن، آسان طریقے سے',
    'savedEstimates': 'محفوظ تخمینے',
    'noEstimates': 'ابھی کوئی تخمینہ نہیں',
    'noEstimatesHint': 'پہلا پینٹ تخمینہ بنانے کے لیے + دبائیں۔',
    'newEstimate': 'نیا تخمینہ',
    'edit': 'ترمیم',
    'duplicate': 'نقل',
    'delete': 'حذف کریں',
    'confirmDelete': 'تخمینہ حذف کریں؟',
    'confirmDeleteMsg': 'یہ تخمینہ مستقل طور پر حذف ہو جائے گا۔',
    'cancel': 'منسوخ کریں',
    'yesDelete': 'حذف کریں',
    'save': 'محفوظ کریں',
    'settings': 'ترتیبات',
    'language': 'زبان',
    'english': 'انگریزی',
    'urdu': 'اردو',
    'currency': 'کرنسی',
    'currencyNote':
        'ریٹس منتخب کرنسی میں درج کیے جاتے ہیں۔ کوئی لائیو تبدیلی نہیں۔',
    'units': 'اکائیاں',
    'feet': 'فٹ + انچ',
    'meters': 'میٹر',
    'defaultUnit': 'پہلے سے طے شدہ اکائی',
    'doorSize': 'دروازے کا معیاری سائز',
    'windowSize': 'کھڑکی کا معیاری سائز',
    'labourRate': 'مزدوری کی شرح',
    'puttyRate': 'پٹی کی شرح',
    'primerRate': 'پرائمر کی شرح',
    'emulsionCoverage': 'ایملشن کوریج',
    'primerCoverage': 'پرائمر کوریج',
    'distemperCoverage': 'ڈسٹیمپر کوریج',
    'perSqFt': 'فی مربع فٹ',
    'perLiter': 'فی لیٹر',
    'sqFtPerLiter': 'مربع فٹ / لیٹر / کوٹ',
    'ratesNote':
        'یہ صرف ابتدائی اقدار ہیں۔ ان پر بھروسہ کرنے سے پہلے کسی اصلی پینٹر سے ریٹس اور کوریج کی تصدیق کر لیں۔',
    'brandRates': 'برانڈ ریٹس',
    'ratePerLiter': 'فی لیٹر شرح',
    'coveragePerLiter': 'کوریج (مربع فٹ / لیٹر)',
    'resetRates': 'ریٹس پہلے جیسے کر دیں',
    'ratesReset': 'ریٹس پہلے جیسے ہو گئے',
    'settingsSaved': 'ترتیبات محفوظ ہو گئیں',
    'estimateTitle': 'تخمینے کا عنوان',
    'brand': 'پینٹ برانڈ',
    'paintType': 'پینٹ کی قسم',
    'emulsion': 'ایملشن',
    'distemper': 'ڈسٹیمپر',
    'rooms': 'کمرے',
    'addRoom': 'کمرہ شامل کریں',
    'roomName': 'کمرے کا نام',
    'length': 'لمبائی',
    'width': 'چوڑائی',
    'height': 'اونچائی',
    'inches': 'انچ',
    'includeCeiling': 'چھت بھی شامل کریں',
    'doors': 'دروازے',
    'windows': 'کھڑکیاں',
    'wallArea': 'دیواروں کا رقبہ',
    'ceilingArea': 'چھت کا رقبہ',
    'paintableArea': 'پینٹ کرنے والا رقبہ',
    'primer': 'پرائمر (1 کوٹ)',
    'paint': 'پینٹ (2 کوٹ)',
    'putty': 'پٹی',
    'labour': 'مزدوری',
    'materialCost': 'سامان کی لاگت',
    'totalCost': 'کل تخمینہ',
    'grandTotal': 'کل رقم',
    'liters': 'لیٹر',
    'packs': 'ڈبے',
    'pack16': '16 لیٹر والے ڈبے',
    'pack4': '4 لیٹر والے ڈبے',
    'viewResult': 'نتیجہ دیکھیں',
    'calculate': 'حساب کریں',
    'quotation': 'کوٹیشن',
    'validity': '7 دن کے لیے درست',
    'validUntil': 'درست ہے تا',
    'sharePdf': 'پی ڈی ایف شیئر کریں',
    'shareText': 'متن شیئر کریں',
    'share': 'شیئر کریں',
    'date': 'تاریخ',
    'notes': 'نوٹس',
    'painterDetails': 'پینٹر کی تفصیل',
    'customerDetails': 'گاہک کی تفصیل',
    'painterName': 'پینٹر کا نام',
    'painterPhone': 'پینٹر کا فون',
    'customerName': 'گاہک کا نام',
    'required': 'ضروری ہے',
    'invalidNumber': 'صحیح عدد درج کریں',
    'addRoomFirst': 'پہلے کم از کم ایک کمرہ شامل کریں۔',
    'puttyToggle': 'پٹی شامل کریں',
    'quotationTitle': 'پینٹ کوٹیشن',
    'createdOn': 'بنایا گیا',
    'estimateSaved': 'تخمینہ محفوظ ہو گیا',
    'room': 'کمرہ',
    'livingRoom': 'بیٹھک',
    'bedroom': 'سونے کا کمرہ',
    'kitchen': 'باورچی خانہ',
    'bathroom': 'غسل خانہ',
    'editRoom': 'کمرہ تبدیل کریں',
    'saveRoom': 'کمرہ محفوظ کریں',
    'sqFt': 'مربع فٹ',
    'sqM': 'مربع میٹر',
    'totalLiters': 'کل لیٹر',
    'cost': 'لاگت',
    'breakdown': 'تفصیل',
    'makeQuotation': 'کوٹیشن بنائیں',
    'enterTitle': 'عنوان درج کریں، مثلاً گھر کا پینٹ',
    'noRoomsYet': 'ابھی کوئی کمرہ شامل نہیں۔',
    'areaUnit': 'رقبہ',
  },
};

/// Holds the current language, persists it, and translates keys.
class LanguageProvider extends ChangeNotifier {
  LanguageProvider({String initialLanguage = 'en'})
      : _language = initialLanguage;

  String _language;

  String get language => _language;

  bool get isUrdu => _language == 'ur';

  /// Text direction for the current language.
  TextDirection get textDirection =>
      isUrdu ? TextDirection.rtl : TextDirection.ltr;

  String t(String key) {
    final Map<String, String>? langMap = localizedStrings[_language];
    final String? value = langMap?[key];
    if (value != null) {
      return value;
    }
    // Fall back to English, then to the key itself.
    return localizedStrings['en']?[key] ?? key;
  }

  Future<void> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? saved = prefs.getString(_languageKey);
    if (saved != null && localizedStrings.containsKey(saved)) {
      _language = saved;
      notifyListeners();
    }
  }

  Future<void> setLanguage(String code) async {
    if (!localizedStrings.containsKey(code)) {
      return;
    }
    _language = code;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, code);
    notifyListeners();
  }

  /// Pure helper for tests: translate without a provider instance.
  static String translate(String language, String key) {
    return localizedStrings[language]?[key] ??
        localizedStrings['en']?[key] ??
        key;
  }
}
