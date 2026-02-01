// 메인화면

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/color_constants.dart';
import '../../widgets/atoms/light_diffusion_background.dart';

import '../../models/auth_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/care_provider.dart';

import '../accident/alarm_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.watch는 데이터가 바뀌면 화면을 다시 그리라는 신호입니다.
    // 서버에서 가져온 전체 목록 상태 (로딩/에러/데이터 포함)
    final careListAsync = ref.watch(careListProvider);

    // 위 목록 중 현재 사용자가 선택한 어르신 한 분의 정보
    final selectedCare = ref.watch(selectedCareProvider);

    return LightDiffusionBackground(
      child: Container(
        color: Colors.transparent,
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 120), // 내비바 공간 확보
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context), // 상단 헤더 (메뉴 & 알림)
                const SizedBox(height: 24),
                _buildMainDropdown(
                  ref,
                  careListAsync,
                  selectedCare,
                ), // 어르신 드롭다운
                const SizedBox(height: 32),
                _buildStatusCard(), // 안심 상태 카드
                const SizedBox(height: 32),
                _buildRobotSection(context), // 로봇 상태 및 바텀시트 트리거
                // HomeScreen 내부 Column의 children 중 하나로 추가
                ElevatedButton(
                  onPressed: () {
                    // 🚨 401 에러가 발생했을 때와 동일한 '로그아웃' 명령을 강제로 내립니다.
                    ref.read(authProvider.notifier).logout();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text(
                    "세션 만료 강제 테스트",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 32),
                _buildAgendaSection(), // 오늘의 일정
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- [위젯] 상단 헤더 ---
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Text(
              "No-ill",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6A85B6),
              ),
            ),
          ],
        ),
        // ✅ [수정] 클릭 가능한 알림 아이콘
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AlarmScreen(),
              ), // 알림 목록으로 이동
            );
          },
          borderRadius: BorderRadius.circular(20), // 클릭 피드백 영역
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: const Icon(
              Icons.notifications_none,
              size: 24,
              color: NoIllColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  // --- [신규] 메인 구역 드롭다운 위젯 ---
  Widget _buildMainDropdown(
    WidgetRef ref,
    AsyncValue<List<PetRequest>> listAsync,
    PetRequest? selected,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: NoIllColors.primary.withOpacity(0.3)),
      ),
      child: listAsync.when(
        data: (list) => DropdownButton<String>(
          value: selected?.petId,
          isExpanded: true, // 너비를 꽉 채우게
          icon: const Icon(
            Icons.arrow_drop_down_circle_outlined,
            color: NoIllColors.primary,
          ),
          underline: const SizedBox(),
          items: list
              .map(
                (pet) => DropdownMenuItem(
                  value: pet.petId,
                  child: Text(
                    "${pet.careName} (${pet.petName})", // "어머니 댁 (복순이)" 형태
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (id) =>
              ref.read(selectedPetIdProvider.notifier).state = id,
        ),
        loading: () => const CircularProgressIndicator(),
        error: (_, __) => const Text("데이터를 불러올 수 없습니다."),
      ),
    );
  }

  // --- [위젯] 안심 상태 카드 ---
  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: NoIllColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.home_outlined,
                size: 60,
                color: NoIllColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.check_circle, color: NoIllColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                "STATUS: SAFE",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: NoIllColors.primary,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "특이사항 없습니다.",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const Text(
            "마지막 업데이트: 2 minutes ago",
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // --- [위젯] 로봇 섹션 ---
  Widget _buildRobotSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Companion: Aibo-Bot v2",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        // _buildRobotSection 내 카드 디자인 수정 부분
        InkWell(
          onTap: () => _showModeBottomSheet(context, "순찰모드"),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              children: [
                // 배터리 아이콘 대신 '순찰모드' 아이콘 적용
                const Icon(
                  Icons.visibility_outlined,
                  color: NoIllColors.primary,
                  size: 30,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    // 텍스트를 기기 모드 상태로 변경
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
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildActionBtn(Icons.videocam, "View Camera"),
            const SizedBox(width: 12),
            _buildActionBtn(Icons.phone, "Call Pet"),
          ],
        ),
      ],
    );
  }

  Widget _buildActionBtn(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: NoIllColors.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- [위젯] 오늘의 일정 ---
  Widget _buildAgendaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Today’s Agenda",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildAgendaItem("Evening Check-in", "6:00 PM", true),
        _buildAgendaItem("Morning Medication", "8:30 AM", false, isDone: true),
      ],
    );
  }

  Widget _buildAgendaItem(
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
