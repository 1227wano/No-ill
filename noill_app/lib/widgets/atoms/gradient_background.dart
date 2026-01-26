// auth 및 온보딩 화면에 대한 그라데이션 배경 위젯

import 'package:flutter/material.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;

  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFE0F2FE), // 연한 소라색
            Color(0xFFFEF9F0), // 밀키 아이보리
            Colors.white,
          ],
        ),
      ),
      child: child,
    );
  }
}
