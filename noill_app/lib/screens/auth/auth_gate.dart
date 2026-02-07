// lib/screens/auth/auth_gate.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../main_screen.dart';
import 'login_screen.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return switch (authState.status) {
    // 초기/로딩
      AuthStatus.initial || AuthStatus.loading => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),

    // 로그인됨
      AuthStatus.authenticated => const MainScreen(),

    // 로그아웃/에러
      AuthStatus.unauthenticated || AuthStatus.error => const LoginScreen(),
    };
  }
}
