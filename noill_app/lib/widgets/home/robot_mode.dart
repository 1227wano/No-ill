// 로봇 모드 설명
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/color_constants.dart';
import '../../providers/care_provider.dart';

class RobotSection extends ConsumerWidget {
  const RobotSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCare = ref.watch(selectedPetProvider);
    final robotName = selectedCare?.petName ?? '노일봇';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("$robotName 상태", "로봇의 현재 모드와 상태를 알려드려요"),
        SizedBox(height: 8.h),
        _buildModeButton(context, "순찰모드"),
      ],
    );
  }

  // 로봇 섹션 전용 헤더 (HomeScreen의 것과 동일한 스타일)
  Widget _buildSectionHeader(String title, String subtitle) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800),
        ),
        SizedBox(width: 8.w),
        Text(
          subtitle,
          style: TextStyle(fontSize: 11.sp, color: Colors.black45),
        ),
      ],
    );
  }

  Widget _buildRobotIcon() {
    return Container(
      width: 50.w,
      height: 50.w,
      decoration: BoxDecoration(
        color: NoIllColors.primary.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.smart_toy_rounded, color: NoIllColors.primary),
    );
  }

  Widget _buildStatusTag(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14.sp, color: color),
        SizedBox(width: 2.w),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildModeButton(BuildContext context, String currentMode) {
    return InkWell(
      onTap: () => _showModeBottomSheet(context, currentMode),
      child: Container(
        padding: EdgeInsets.all(18.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            const Icon(Icons.visibility_outlined, color: NoIllColors.primary),
            SizedBox(width: 16.w),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "순찰모드 / 주행모드 더 알아보기",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  "정해진 구역을 이상 없이 체크 중",
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.keyboard_arrow_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showModeBottomSheet(BuildContext context, String currentMode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => _buildBottomSheetContent(currentMode),
    );
  }

  Widget _buildBottomSheetContent(String currentMode) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "기기 모드 조회",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildModeItem("순찰모드", "이상 징후를 체크합니다.", Icons.visibility, true),
          _buildModeItem("주행모드", "어르신을 따라다닙니다.", Icons.directions_run, false),
        ],
      ),
    );
  }

  Widget _buildModeItem(
    String title,
    String desc,
    IconData icon,
    bool isSelected,
  ) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? NoIllColors.primary : Colors.grey,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? NoIllColors.primary : Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(desc),
      selected: isSelected,
    );
  }
}
