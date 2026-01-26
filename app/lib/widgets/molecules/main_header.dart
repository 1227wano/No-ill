// 공통 헤더
import 'package:flutter/material.dart';
import '../../core/constants/color_constants.dart';

class MainHeader extends StatelessWidget implements PreferredSizeWidget {
  final String userName;
  final VoidCallback? onNotifyPressed;

  const MainHeader({super.key, required this.userName, this.onNotifyPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 어르신 프로필 스위처
          InkWell(
            onTap: () => print("어르신 교체 팝업 노출"),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundImage: AssetImage('assets/images/user_profile.png'),
                ),
                const SizedBox(width: 12),
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(Icons.keyboard_arrow_down, color: Colors.grey[400]),
              ],
            ),
          ),
          // 알림 아이콘
          IconButton(
            onPressed: onNotifyPressed,
            icon: Container(
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
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(70);
}
