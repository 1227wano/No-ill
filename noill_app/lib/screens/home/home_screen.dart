import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:noill_app/providers/care_provider.dart';
import 'package:noill_app/screens/call/call_screen.dart';

// 분리된 위젯들 임포트
import '../../widgets/atoms/light_diffusion_background.dart';
import '../../widgets/home/event_banner.dart'; // LatestAccidentBanner
import '../../widgets/home/care_dropdown.dart'; // CareDropdown
import '../../widgets/home/status_card.dart'; // StatusCard
import '../../widgets/home/robot_mode.dart'; // RobotSection
import '../../widgets/home/daily_schedule.dart'; // DailyScheduleSection

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: LightDiffusionBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 100.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 16.h),
                  const LatestAccidentBanner(),

                  _buildSectionHeader("어르신 선택", "보호 중인 어르신 목록이에요"),

                  // 🎯 드롭다운과 통화 버튼 가로 배치
                  Row(
                    children: [
                      const Expanded(child: CareDropdown()),
                      SizedBox(width: 8.w),
                      SizedBox(
                        width: 60.w,
                        height: 52.h,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6A85B6),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            final selectedPet = ref.read(selectedPetProvider);
                            if (selectedPet == null) return;

                            // 발신 화면으로 이동 (startCall은 화면 내부에서 호출됨)
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VideoCallScreen(
                                  petId: selectedPet.petId,
                                  careName: selectedPet.careName,
                                ),
                              ),
                            );
                          },
                          child: const Icon(Icons.videocam_rounded, size: 28),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 32.h),
                  _buildSectionHeader("실시간 상태", "어르신이 안전하게 계신지 확인하세요"),
                  const StatusCard(),

                  SizedBox(height: 32.h),
                  const RobotSection(),

                  SizedBox(height: 32.h),
                  _buildSectionHeader("오늘의 일정", "예정된 주요 일과들이에요"),
                  const DailyScheduleSection(), // 🎯 하단 매핑 로직 확인
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 섹션 헤더는 공통으로 쓰이므로 홈 화면에 private으로 남기거나 atoms로 분리 가능합니다.
  Widget _buildSectionHeader(String title, String subtitle) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w, bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 11.sp,
                color: Colors.black45,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
