import 'package:flutter/material.dart';
import 'presentation/onboarding/onboarding_screen.dart';
import 'ui/app_theme.dart';

void main() {
  runApp(const MyCareApp());
}

class MyCareApp extends StatelessWidget {
  const MyCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My-Care',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const OnboardingRoot(),
    );
  }
}
