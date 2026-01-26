import 'package:flutter/material.dart';
import 'package:noill_app/core/theme/app_theme.dart';
import 'package:noill_app/screens/auth/splash_screen.dart';

void main() {
  runApp(const NoIllApp());
}

class NoIllApp extends StatelessWidget {
  const NoIllApp({super.key});

  // This widget is the root of your application.

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(), // 시작점 설정
    );
  }
}
