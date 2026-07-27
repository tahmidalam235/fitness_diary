import 'package:flutter/material.dart';

import 'core/di/injection.dart';
import 'core/routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await setupInjection();

  runApp(const FitnessDiaryApp());
}

class FitnessDiaryApp extends StatelessWidget {
  const FitnessDiaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      theme: ThemeData(useMaterial3: true),
    );
  }
}
