// 전체 앱의 진입점
// 모든 화면의 일관성 담당
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noill_app/core/theme/app_theme.dart';
import 'package:noill_app/screens/auth/splash_screen.dart';
import 'screens/home/home_screen.dart';

void main() {
  // provider: 전역 저장소
  runApp(const ProviderScope(child: NoIllApp()));
}

class NoIllApp extends StatelessWidget {
  const NoIllApp({super.key});

  // This widget is the root of your application.

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'No-ill App',
      theme: AppTheme.lightTheme.copyWith(),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(), // 시작점 설정
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
