// 메인화면

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // ✅ 사이즈 대응을 위해 추가 권장

import '../../core/constants/color_constants.dart';
import '../../widgets/atoms/light_diffusion_background.dart';
import '../../widgets/atoms/custom_card.dart';

import '../../models/auth_models.dart';
import '../../providers/event_provider.dart';
import '../../providers/care_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.watch는 데이터가 바뀌면 화면을 다시 그리라는 신호입니다.
    // 💡 이제 AsyncValue가 아니라 실제 List<PetRequest>가 반환됩니다.
    final careList = ref.watch(careListProvider);
    final selectedCare = ref.watch(selectedCareProvider);

    // 💡 [핵심] 24시간 이내 사고 리스트를 가져옵니다.
    final activeAlarmsAsync = ref.watch(activeAlarmsProvider);

    // 💡 데이터가 있고, 리스트가 비어있지 않으면 '경고' 상태로 정의합니다.
    final bool isWarning = activeAlarmsAsync.maybeWhen(
      data: (alarms) => alarms.isNotEmpty,
      orElse: () => false,
    );

    return LightDiffusionBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // ✅ 3. 상단 내비게이션(배경) 색상 최적화 (AppBar 제거 후 바디 상단 여백 활용)
        body: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            // ✅ 2. 하단 내비게이션 밀착을 위해 패딩 조정 (80~100 정도로 하향)
            padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 100.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 16.h), // 최상단 여백
                // ✅ 1. 드롭다운: 목록이 없어도 일정한 버튼 디자인 유지
                _buildSectionHeader("어르신 선택", "보호 중인 어르신 목록이에요"),
                SizedBox(height: 8.h),
                _buildMainDropdown(ref, careList, selectedCare),
                SizedBox(height: 32.h), // ✅ 섹션 간 표준 간격
                // ✅ 4. STATUS 카드: 슬림하고 모던한 카드 디자인 적용
                _buildSectionHeader("실시간 상태", "어르신이 안전하게 계신지 확인하세요"),
                SizedBox(height: 12.h),
                _buildStatusCard(
                  name: selectedCare?.careName ?? "어르신",
                  isWarning: isWarning,
                ),
                SizedBox(height: 32.h),

                //
                _buildSectionHeader(
                  "${selectedCare?.careName ?? '어르신'}님의 ${selectedCare?.petName ?? '로봇'}",
                  "로봇의 현재 모드와 상태를 알려드려요",
                ),
                SizedBox(height: 8.h),
                _buildRobotSection(context, selectedCare),
                SizedBox(height: 32.h),
                // 일정
                _buildSectionHeader("오늘의 일정", "예정된 주요 일과들이에요"),
                SizedBox(height: 8.h),
                _buildscheduleSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- 1. 개선된 메인 드롭다운 (공통 컴포넌트 적용) ---
  Widget _buildMainDropdown(
    WidgetRef ref,
    List<PetRequest> list,
    PetRequest? selected,
  ) {
    // ✅ 1. Container 대신 CustomCard를 최상위에 둡니다.
    return CustomCard(
      onTap: null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      // 만약 유리 같은 느낌을 주고 싶다면 CustomCard 내부의 decoration을 수정하거나
      // 아래처럼 파라미터로 넘기도록 CustomCard를 확장해서 써야 합니다.
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected?.petId,
          isExpanded: true,
          hint: const Text("등록된 어르신이 없습니다."),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.grey,
          ),
          items: list.isEmpty
              ? null
              : list
                    .map(
                      (pet) => DropdownMenuItem(
                        value: pet.petId,
                        child: Text(
                          "${pet.careName} (${pet.petName})",
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    )
                    .toList(),
          onChanged: (id) =>
              ref.read(selectedPetIdProvider.notifier).state = id,
        ),
      ),
    );
  }

  // 모든 위젯에 공통으로 들어가는 라벨링
  Widget _buildSectionHeader(String title, String subtitle) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic, // 글자 하단 라인을 맞춤
        children: [
          // 메인 타이틀 (굵고 진하게)
          Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
              color: Colors.black,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(width: 8.w), // 타이틀과 설명 사이 간격
          // 서브 설명 (얇고 연하게)
          Expanded(
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 11.sp,
                color: Colors.black45,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis, // 너무 길면 생략 처리
            ),
          ),
        ],
      ),
    );
  }

  // --- 4. 개선된 STATUS 카드 (슬림 & 모던) ---
  Widget _buildStatusCard({required String name, required bool isWarning}) {
    final Color bgColor = isWarning
        ? const Color(0xFFFFEBEE)
        : const Color(0xFFF0F7FF);
    final Color pointColor = isWarning ? Colors.red : NoIllColors.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          // 좌측 아이콘 배지
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isWarning
                  ? Icons.warning_amber_rounded
                  : Icons.health_and_safety_outlined,
              color: pointColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          // 우측 텍스트 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isWarning ? "STATUS: WARNING" : "STATUS: SAFE",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: pointColor.withOpacity(0.7),
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isWarning ? "$name님 낙상 감지!" : "$name님은 안전합니다.",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 5. 로봇 섹션 (기능 없는 버튼 제거) ---
  Widget _buildRobotSection(BuildContext context, PetRequest? selectedCare) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _showModeBottomSheet(context, "순찰모드"),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.visibility_outlined,
                  color: NoIllColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "현재 모드: 순찰모드",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      "정해진 구역을 이상 없이 체크 중",
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
                const Spacer(),
                const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
              ],
            ),
          ),
        ),
        // ✅ 5. View Camera, Call Pet 버튼 삭제 완료
      ],
    );
  }

  // --- [위젯] 오늘의 일정 ---
  Widget _buildscheduleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildscheduleItem("Evening Check-in", "6:00 PM", true),
        _buildscheduleItem(
          "Morning Medication",
          "8:30 AM",
          false,
          isDone: true,
        ),
      ],
    );
  }

  Widget _buildscheduleItem(
    String title,
    String time,
    bool isUrgent, {
    bool isDone = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isUrgent
                  ? NoIllColors.danger.withOpacity(0.1)
                  : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              isUrgent ? Icons.warning_amber : Icons.medication,
              color: isUrgent ? NoIllColors.danger : Colors.grey,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  decoration: isDone ? TextDecoration.lineThrough : null,
                ),
              ),
              Text(
                isDone ? "Completed at $time" : time,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }

  // --- [함수] 기기 모드 바텀 시트 ---
  // 1. 바텀시트를 '실행'하는 함수
  void _showModeBottomSheet(BuildContext context, String currentMode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 전체 화면 높이 대응을 위해 필수
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      // 여기서 아래에 정의한 ②번 콘텐츠 위젯을 호출합니다.
      builder: (context) => _buildModeBottomSheetContent(context, currentMode),
    );
  }

  // 2. 바텀시트의 '내용(UI)'을 그리는 함수
  Widget _buildModeBottomSheetContent(
    BuildContext context,
    String currentMode,
  ) {
    return Padding(
      padding: EdgeInsets.only(
        // 키보드나 시스템 바에 가려지지 않게 하단 여백 자동 조절
        bottom: MediaQuery.of(context).viewInsets.bottom + 40,
        top: 12,
        left: 24,
        right: 24,
      ),
      child: SingleChildScrollView(
        // 내용이 길어도 픽셀이 깨지지 않게 스크롤 허용
        child: Column(
          mainAxisSize: MainAxisSize.min, // 내용물만큼만 높이 차지
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 핸들러 바
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "기기 모드 조회",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // 각 모드 아이템들
            _buildModeItem(
              "취침모드",
              "로봇이 충전기로 돌아가 소음을 줄이고 동작을 멈춥니다.",
              Icons.nightlight_round,
              currentMode == "취침모드",
            ),
            _buildModeItem(
              "순찰모드",
              "로봇이 정해진 구역을 일정 간격으로 돌며 어르신을 찾고, 이상 징후를 체크합니다.",
              Icons.visibility,
              currentMode == "순찰모드",
            ),
            _buildModeItem(
              "주행모드",
              "어르신을 따라다니며 말벗이 되어드리고 낙상 위험을 감지합니다.",
              Icons.local_police,
              currentMode == "주행모드",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeItem(
    String title,
    String desc,
    IconData icon,
    bool isSelected,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected
            ? NoIllColors.primary.withOpacity(0.05)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        border: isSelected
            ? Border.all(color: NoIllColors.primary, width: 1.5)
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: isSelected ? NoIllColors.primary : Colors.grey[600],
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isSelected ? NoIllColors.primary : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
