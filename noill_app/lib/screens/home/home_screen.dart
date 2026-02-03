import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
    return LightDiffusionBackground(
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

                const LatestAccidentBanner(), // 1. 실시간 사고 알림 (FCM 이미지)

                _buildSectionHeader("어르신 선택", "보호 중인 어르신 목록이에요"),
                const CareDropdown(), // 2. 어르신 드롭다운 (데이터 자가 매핑)

                SizedBox(height: 32.h),
                _buildSectionHeader("실시간 상태", "어르신이 안전하게 계신지 확인하세요"),
                const StatusCard(), // 3. 상태 카드 (isWarning 자가 판단)

                SizedBox(height: 32.h),
                const RobotSection(), // 4. 로봇 상태 및 모드 (데이터 자가 매핑)

                SizedBox(height: 32.h),
                _buildSectionHeader("오늘의 일정", "예정된 주요 일과들이에요"),
                const DailyScheduleSection(), // 5. 일정 목록
              ],
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
