// SOVEREIGN Fase 0 — theme + controller + dashboard (@designer).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme.dart';
import 'ui/app_bootstrap.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const SovereignApp());
}

class SovereignApp extends StatelessWidget {
  const SovereignApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SOVEREIGN — The Resource Economy',
      debugShowCheckedModeBanner: false,
      theme: sovereignTheme(),
      home: const AppBootstrap(),
    );
  }
}
