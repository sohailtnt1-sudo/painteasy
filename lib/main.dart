// PaintEasy — paint estimate + quotation app (Phase 1 MVP).
// Offline-first, no server. Home = saved estimates list.

import 'package:material_ui/material_ui.dart';

import 'screens/home_screen.dart';
import 'services/i18n.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final LanguageProvider languageProvider = LanguageProvider();
  await languageProvider.load();
  runApp(PaintEasyApp(languageProvider: languageProvider));
}

class PaintEasyApp extends StatelessWidget {
  const PaintEasyApp({super.key, required this.languageProvider});

  final LanguageProvider languageProvider;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: languageProvider,
      builder: (BuildContext context, Widget? child) {
        return MaterialApp(
          title: languageProvider.t('appTitle'),
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
            useMaterial3: true,
          ),
          home: Directionality(
            textDirection: languageProvider.textDirection,
            child: HomeScreen(languageProvider: languageProvider),
          ),
        );
      },
    );
  }
}
