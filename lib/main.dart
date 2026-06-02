import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:enercore_app/core/theme/app_theme.dart';
import 'package:enercore_app/core/router/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Use manual mode to prevent edge-to-edge overlap on Android 16
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: SystemUiOverlay.values,
  );
  runApp(const ProviderScope(child: EnercoreApp()));
}

class EnercoreApp extends StatelessWidget {
  const EnercoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Enercore',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: appRouter,
    );
  }
}
