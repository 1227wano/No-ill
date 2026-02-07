// lib/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../providers/care_provider.dart';
import '../../providers/call_provider.dart';
import '../../core/utils/logger.dart';
import '../call/call_screen.dart';
import '../../widgets/atoms/light_diffusion_background.dart';
import '../../widgets/home/event_banner.dart';
import '../../widgets/home/care_dropdown.dart';
import '../../widgets/home/status_card.dart';
import '../../widgets/home/robot_mode.dart';
import '../../widgets/home/daily_schedule.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _logger = AppLogger('HomeScreen');

  @override
  void initState() {
    super.initState();

    // 화면 진입 시 초기 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  /// 초기 데이터 로드
  Future<void> _loadInitialData() async {
    try {
      _logger.info('홈 화면 초기 데이터 로드 시작');

      // 어르신 목록이 비어있으면 로드
      final careList = ref.read(careListProvider);
      if (careList.value?.isEmpty ?? true) {
        await ref.read(careListProvider.notifier).refresh();
      }

      _logger.info('홈 화면 초기 데이터 로드 완료');
    } catch (e, stackTrace) {
      _logger.error('초기 데이터 로드 실패', e, stackTrace);
    }
  }

  /// 통화 시작
  Future<void> _handleVideoCall() async {
    final selectedPet = ref.read(selectedPetProvider);

    // 선택된 어르신 확인
    if (selectedPet == null) {
      _showError('통화할 어르신을 먼저 선택해주세요');
      return;
    }

    _logger.info('통화 시작: ${selectedPet.petName} (${selectedPet.petId})');

    try {
      // 통화 화면으로 이동
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoCallScreen(
            petId: selectedPet.petId,
            careName: selectedPet.careName,
          ),
        ),
      );
    } catch (e, stackTrace) {
      _logger.error('통화 화면 이동 실패', e, stackTrace);
      if (mounted) {
        _showError('통화 화면을 열 수 없습니다');
      }
    }
  }

  /// 에러 메시지 표시
  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 8.w),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 선택된 어르신 감지
    final selectedPet = ref.watch(selectedPetProvider);
    final hasSelectedPet = selectedPet != null;

    return SafeArea(
      child: LightDiffusionBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: _loadInitialData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 100.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 16.h),

                    // 최근 사고 배너
                    const LatestAccidentBanner(),

                    // 어르신 선택 섹션
                    _buildSectionHeader(
                      "어르신 선택",
                      "보호 중인 어르신 목록이에요",
                    ),

                    // 드롭다운 + 통화 버튼
                    _buildCareSelectionRow(hasSelectedPet),

                    SizedBox(height: 32.h),

                    // 실시간 상태 섹션
                    _buildSectionHeader(
                      "실시간 상태",
                      "어르신이 안전하게 계신지 확인하세요",
                    ),
                    const StatusCard(),

                    SizedBox(height: 32.h),

                    // 로봇 모드 섹션
                    const RobotSection(),

                    SizedBox(height: 32.h),

                    // 오늘의 일정 섹션
                    _buildSectionHeader(
                      "오늘의 일정",
                      "예정된 주요 일과들이에요",
                    ),
                    const DailyScheduleSection(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Widget Builders
  // ═══════════════════════════════════════════════════════════════════════

  /// 섹션 헤더
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

  /// 어르신 선택 + 통화 버튼 행
  Widget _buildCareSelectionRow(bool hasSelectedPet) {
    return Row(
      children: [
        // 어르신 선택 드롭다운
        const Expanded(child: CareDropdown()),

        SizedBox(width: 8.w),

        // 영상통화 버튼
        _buildVideoCallButton(hasSelectedPet),
      ],
    );
  }

  /// 영상통화 버튼
  Widget _buildVideoCallButton(bool enabled) {
    return SizedBox(
      width: 60.w,
      height: 52.h,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled
              ? const Color(0xFF6A85B6)
              : Colors.grey.shade300,
          foregroundColor: enabled ? Colors.white : Colors.grey.shade500,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: enabled ? 2 : 0,
          disabledBackgroundColor: Colors.grey.shade300,
          disabledForegroundColor: Colors.grey.shade500,
        ),
        onPressed: enabled ? _handleVideoCall : null,
        child: Icon(
          Icons.videocam_rounded,
          size: 28.sp,
        ),
      ),
    );
  }
}
