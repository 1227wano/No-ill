// lib/widgets/molecules/main_app_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/color_constants.dart';
import '../../screens/accident/alarm_screen.dart';

class MainAppBar extends ConsumerWidget implements PreferredSizeWidget {
  // 이제 앱바에서는 드롭다운을 쓰지 않으므로 옵션이 필요 없습니다.
  const MainAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleSpacing: 20,

      // 1. 왼쪽: 깔끔한 브랜드 로고
      title: const Text(
        "No-ill",
        style: TextStyle(
          color: Color(0xFF6A85B6),
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),

      // 2. 오른쪽: 알림 버튼 (기존 유지)
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AlarmScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none,
                color: NoIllColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
