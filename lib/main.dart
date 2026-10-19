import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/app_state.dart';
import 'core/theme.dart';
import 'screens/root_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor: Colors.transparent));
  final prefs = await SharedPreferences.getInstance();
  final state = AppState(prefs);
  runApp(AppScope(notifier: state, child: const ArabAcademyApp()));
  state.loadCatalog();
}

class ArabAcademyApp extends StatelessWidget {
  const ArabAcademyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: state.lang == 'en' ? 'Arab Academy' : 'الأكاديمية العربية',
      locale: state.lang == 'en' ? const Locale('en', 'US') : const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeMode: state.themeMode,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeAnimationDuration: const Duration(milliseconds: 450),
      themeAnimationCurve: Curves.easeOutCubic,
      home: const RootShell(),
    );
  }
}
