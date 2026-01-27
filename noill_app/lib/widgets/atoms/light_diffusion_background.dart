// 전체 배경용 (auth, 온보딩 제외) 전체 테마

import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/color_constants.dart';

class LightDiffusionBackground extends StatelessWidget {
  final Widget child;

  const LightDiffusionBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. 베이스는 우리가 정한 밀키 아이보리
        Container(color: NoIllColors.background),

        // 2. 아주 희미한 확산광 (Blur)
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
          child: Stack(
            children: [
              // 우측 상단: 거의 보일듯 말듯한 푸른 빛
              Positioned(
                top: -100,
                right: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    color: NoIllColors.primary.withOpacity(0.2), // 6%의 아주 연한 농도
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // 좌측 하단: 은은한 반사광
              Positioned(
                bottom: -150,
                left: -80,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    color: NoIllColors.primary.withOpacity(0.2), // 4%의 농도
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
        child,
      ],
    );
  }
}
