// 하단 내비게이션 바
// UI를 담당하는 위젯

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
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 30), // 바닥에서 살짝 띄움
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35), // 완전한 캡슐 모양
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
          _buildNavItem(1, Icons.search_rounded),
          _buildNavItem(2, Icons.calendar_today_rounded),
          _buildNavItem(3, Icons.settings_rounded),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          // 선택된 아이콘에만 연한 소라색 배경
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
