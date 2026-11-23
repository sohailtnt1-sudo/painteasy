import 'package:flutter_test/flutter_test.dart';
import 'package:painteasy/main.dart';
import 'package:painteasy/services/i18n.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('PaintEasy app boots and shows the home screen',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final LanguageProvider languageProvider = LanguageProvider();
    await tester.pumpWidget(
      PaintEasyApp(languageProvider: languageProvider),
    );
    await tester.pumpAndSettle();

    expect(find.text('PaintEasy'), findsWidgets);
    expect(find.text('No estimates yet'), findsOneWidget);
  });
}
