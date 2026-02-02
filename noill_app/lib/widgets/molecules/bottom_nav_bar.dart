// lib/widgets/molecules/bottom_nav_bar.dart

import 'package:flutter/material.dart';
import '../../core/constants/color_constants.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // ✅ 2. 바닥 밀착: 하단 여백을 30에서 12로 줄여 바닥에 더 붙어 보이게 조정
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      height: 64, // 높이를 약간 슬림하게 조정
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06), // 그림자를 더 은은하게
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // ✅ 2. 아이콘 균형: Outlined 계열로 통일하여 시각적 무게를 맞춤
          _buildNavItem(0, Icons.home_rounded),
          _buildNavItem(1, Icons.camera_alt_rounded),
          _buildNavItem(2, Icons.calendar_today_outlined),
          _buildNavItem(3, Icons.settings_rounded),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon) {
    final isSelected = currentIndex == index;

    // ✅ 2. 시각적 크기 보정: 아이콘마다 미세하게 다른 크기 감각 조정
    double iconSize = 26;
    if (icon == Icons.calendar_today_outlined) {
      iconSize = 24; // 선이 얇은 아이콘은 소폭 조정
    }

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque, // 터치 영역 확보
      child: Container(
        width: 50, // 아이콘 클릭 영역 균등 배분
        height: 50,
        decoration: BoxDecoration(
          color: isSelected
              ? NoIllColors.primary.withOpacity(0.1)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isSelected ? NoIllColors.primary : Colors.grey.shade400,
          size: iconSize,
        ),
      ),
    );
  }
}
