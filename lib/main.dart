import 'package:flutter/material.dart';

import 'core/routes/app_router.dart';

void main() {
  runApp(const FitnessDiaryApp());
}

class FitnessDiaryApp extends StatelessWidget {
  const FitnessDiaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      theme: ThemeData(
        useMaterial3: true,
      ),
    );
  }
}