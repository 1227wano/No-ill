// 메인화면

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/color_constants.dart';
import '../../widgets/atoms/light_diffusion_background.dart';

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
      child: Container(
        color: Colors.transparent,
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 120), // 내비바 공간 확보
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                _buildMainDropdown(ref, careList, selectedCare), // 어르신 드롭다운
                const SizedBox(height: 32),
                _buildStatusCard(
                  name: selectedCare?.careName ?? "어르신",
                  isWarning: isWarning,
                ), // 안심 상태 카드
                const SizedBox(height: 32),
                _buildRobotSection(context), // 로봇 상태 및 바텀시트 트리거

                const SizedBox(height: 32),
                _buildAgendaSection(), // 오늘의 일정
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- [신규] 메인 구역 드롭다운 위젯 ---
  Widget _buildMainDropdown(
    WidgetRef ref,
    List<PetRequest> list,
    PetRequest? selected,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: NoIllColors.primary.withOpacity(0.3)),
      ),
      child: list.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text("등록된 어르신이 없습니다."),
            )
          : DropdownButton<String>(
              value: selected?.petId,
              isExpanded: true,
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
                        "${pet.careName} (${pet.petName})",
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
    );
  }

  // --- [위젯] 안심 상태 카드 ---
  Widget _buildStatusCard({required String name, required bool isWarning}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: isWarning
                ? Colors.red.withOpacity(0.1) // 🚨 위험 시 붉은 그림자
                : Colors.black.withOpacity(0.05),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        children: [
          // 1. 상태 아이콘 영역
          Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isWarning
                  ? Colors.red[50]
                  : NoIllColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isWarning ? Icons.warning_rounded : Icons.home_outlined,
              size: 60,
              color: isWarning ? Colors.red : NoIllColors.primary,
            ),
          ),
          const SizedBox(height: 20),

          // 2. 상태 텍스트 배지
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isWarning ? Icons.error : Icons.check_circle,
                color: isWarning ? Colors.red : NoIllColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isWarning ? "STATUS: WARNING" : "STATUS: SAFE",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isWarning ? Colors.red : NoIllColors.primary,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 3. 메인 안내 문구
          Text(
            isWarning ? "$name님께 낙상이 감지되었습니다!" : "$name님은 현재 안전합니다.",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          Text(
            isWarning ? "즉시 확인이 필요합니다." : "특이사항 없습니다.",
            style: TextStyle(
              color: isWarning ? Colors.redAccent : Colors.grey,
              fontSize: 14,
              fontWeight: isWarning ? FontWeight.bold : FontWeight.normal,
            ),
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
