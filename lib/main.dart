import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'core/di/injection.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/data/theme_service.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await setupInjection();
  runApp(const FitnessDiaryApp());
}

class FitnessDiaryApp extends StatelessWidget {
  const FitnessDiaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeSvc = getIt<ThemeService>();

    return ListenableBuilder(
      listenable: themeSvc,
      builder: (context, _) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeSvc.mode,
          routerConfig: appRouter,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        );
      },
    );
  }
}
