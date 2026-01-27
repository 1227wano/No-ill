import 'dart:ui'; // ImageFilter 사용을 위해 필수
import 'package:flutter/material.dart';
import '../../core/constants/color_constants.dart';

class DualDiffusionBackground extends StatelessWidget {
  final Widget child;

  const DualDiffusionBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final Color baseColor = NoIllColors.background;
    // 진한 푸른색감을 위해 투명도를 낮게(진하게) 설정합니다. (0.5 ~ 0.7 추천)
    final Color glowColorTop = NoIllColors.primary.withOpacity(0.6);
    final Color glowColorBottom = NoIllColors.primary.withOpacity(0.4);

    return Stack(
      fit: StackFit.expand, // 전체 화면을 채우도록 설정
      children: [
        // 1. 기본 배경색 (Milky Ivory) - 가장 밑바탕
        Container(color: baseColor),

        // 2. 빛 확산 레이어 (여기가 핵심입니다!)
        // ImageFiltered를 사용하여 자식 위젯들에 강력한 블러 효과를 적용합니다.
        ImageFiltered(
          imageFilter: ImageFilter.blur(
            sigmaX: 100,
            sigmaY: 100,
          ), // 블러 강도 (높을수록 부드럽게 퍼짐)
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 우측 상단 빛 (화면 밖으로 살짝 나가게 배치)
              Positioned(
                top: -150,
                right: -150,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    color: glowColorTop,
                    shape: BoxShape.circle, // 원형의 진한 빛
                  ),
                ),
              ),
              // 좌측 하단 빛 (우측 상단보다는 조금 작고 연하게)
              Positioned(
                bottom: -120,
                left: -120,
                child: Container(
                  width: 350,
                  height: 350,
                  decoration: BoxDecoration(
                    color: glowColorBottom,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),

        // 3. 실제 화면 콘텐츠 (블러 영향 받지 않음)
        child,
      ],
    );
  }
}
