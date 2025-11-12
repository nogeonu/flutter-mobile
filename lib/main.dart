import 'package:flutter/material.dart';

import 'screens/main_shell.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const HospitalNaviApp());
}

class HospitalNaviApp extends StatelessWidget {
  const HospitalNaviApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CDSSentials',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const MainShell(),
    );
  }
}
