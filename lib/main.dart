import 'package:flutter/material.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const DataIsFunApp());
}

/// Main application widget
class DataIsFunApp extends StatelessWidget {
  const DataIsFunApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Stats is Fun',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}
