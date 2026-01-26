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
      // 레퍼런스 이미지의 플로팅 스타일 구현
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 30),
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(0, Icons.home_rounded),
          _buildNavItem(1, Icons.videocam_rounded), // 화상통화 아이콘으로 변경 추천
          _buildNavItem(2, Icons.calendar_today_rounded),
          _buildNavItem(3, Icons.settings_rounded),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index), // 부모 위젯(MainScreen)에 인덱스 전달
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          // 선택 시 소라색 포인트 효과
          color: isSelected
              ? NoIllColors.primary.withOpacity(0.1)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isSelected ? NoIllColors.primary : Colors.grey,
          size: 28,
        ),
      ),
    );
  }
}
