// lib/screens/home/home_screen.dart

import 'dart:async'; // StreamSubscription 사용을 위해 추가
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:noill_app/core/constants/color_constants.dart';

import '../../providers/care_provider.dart';
import '../../providers/schedule_provider.dart';
import '../../providers/event_provider.dart';

import '../../core/utils/logger.dart';

import '../call/call_screen.dart';
import '../../widgets/atoms/light_diffusion_background.dart';
import '../../widgets/home/event_banner.dart';
import '../../widgets/home/care_dropdown.dart';
import '../../widgets/home/status_card.dart';
import '../../widgets/home/robot_mode.dart';
import '../../widgets/home/daily_schedule.dart';
import '../../core/constants/app_constants.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _logger = AppLogger('HomeScreen');

  // ✅ 리스너 해제를 위한 변수 선언
  StreamSubscription<RemoteMessage>? _fcmSubscription;

  @override
  void initState() {
    super.initState();

    // 앱 켜지자마자 FCM 토큰 출력 (디버깅용)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _printFcmToken();
    });

    // 초기 데이터 로드 및 리스너 설정
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
      _setupFCMListener(); // 앱 켜져있을 때 수신
      _setupInteractedMessage(); // ✅ 앱 꺼져있거나 백그라운드일 때 수신
    });
  }

  @override
  void dispose() {
    // ✅ 화면 종료 시 리스너 해제 (메모리 누수 방지)
    _fcmSubscription?.cancel();
    super.dispose();
  }

  /// FCM 토큰 출력 (디버깅)
  Future<void> _printFcmToken() async {
    try {
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      print("\n========================================");
      print("💌 FCM 알림 토큰 (복사해서 테스트하세요) 💌");
      print(fcmToken);
      print("========================================\n");
    } catch (e) {
      _logger.error("토큰 가져오기 실패", e);
    }
  }

  /// ✅ 앱이 꺼져있거나(Terminated) 백그라운드 상태일 때 알림 클릭 처리
  Future<void> _setupInteractedMessage() async {
    // 1. 앱이 완전히 종료된 상태에서 알림을 누르고 들어온 경우
    RemoteMessage? initialMessage = await FirebaseMessaging.instance
        .getInitialMessage();
    if (initialMessage != null) {
      _handleNewEvent();
    }

    // 2. 앱이 백그라운드(내려가 있음) 상태에서 알림을 누르고 들어온 경우
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNewEvent();
    });
  }

  /// 앱이 켜져 있을 때(Foreground) 메시지 수신 리스너
  void _setupFCMListener() {
    // 기존 리스너가 있다면 취소 후 재등록
    _fcmSubscription?.cancel();

    _fcmSubscription = FirebaseMessaging.onMessage.listen((
      RemoteMessage message,
    ) {
      _logger.info('FCM 메시지 수신(Foreground): ${message.data}');

      // 낙상 사고 알림인지 확인
      if (message.data['type'] == 'FALL_ACCIDENT' ||
          message.notification != null) {
        _handleNewEvent();
      }
    });
  }

  /// 초기 데이터 로드 및 당겨서 새로고침(Pull-to-Refresh)
  Future<void> _loadInitialData() async {
    try {
      _logger.info('홈 화면 데이터 새로고침 시작');

      // 1. 현재 선택된 어르신의 ID 백업
      final currentSelectedId = ref.read(selectedPetIdProvider);

      // 2. 어르신 목록 새로고침
      final newList = await ref.refresh(careListProvider.future);

      // 3. 선택 상태 복구
      if (newList.isNotEmpty) {
        if (currentSelectedId != null) {
          final matchedPet = newList.firstWhere(
            (p) => p.petId == currentSelectedId,
            orElse: () => newList.first,
          );
          ref.read(selectedPetProvider.notifier).update(matchedPet);
        } else {
          ref.read(selectedPetProvider.notifier).update(newList.first);
        }
      }

      // 4. 일정 데이터 새로고침
      await _refreshScheduleData();

      // 5. ✅ 사고 기록 강제 새로고침 (await를 걸어서 로딩 표시가 끝까지 유지되도록 함)
      final selectedPet = ref.read(selectedPetProvider);
      if (selectedPet != null) {
        _logger.info('사고 기록 데이터 최신화');
        // invalidate 대신 refresh(...future)를 써야 await가 먹힙니다.
        await ref.refresh(eventListByPetProvider(selectedPet.petId).future);
      }

      _logger.info('홈 화면 데이터 새로고침 완료');
    } catch (e, stackTrace) {
      _logger.error('데이터 새로고침 실패', e, stackTrace);
    }
  }

  /// 일정 데이터 새로고침
  Future<void> _refreshScheduleData() async {
    // 기존 데이터를 무효화하고 다시 로드될 때까지 기다림
    ref.invalidate(scheduleNotifierProvider);
    await ref.read(scheduleNotifierProvider.future);
  }

  /// 새 이벤트 발생 시 데이터 갱신 (딜레이 포함)
  Future<void> _handleNewEvent() async {
    final selectedPet = ref.read(selectedPetProvider);
    if (selectedPet != null) {
      _logger.info('🚨 새 이벤트 감지! 서버 DB 저장 대기 중...');

      // ✅ 서버의 DB Transaction 속도 이슈로 인한 딜레이 (Race Condition 방지)
      // 추후 서버 로직 개선 시 제거 가능
      if (mounted) {
        await Future.delayed(const Duration(seconds: 1));
      }

      if (mounted) {
        _logger.info('데이터 강제 Refresh 실행');
        // invalidate 대신 refresh를 사용하여 즉시 데이터를 받아옴
        ref.refresh(eventListByPetProvider(selectedPet.petId));
      }
    }
  }

  /// 통화 시작 로직
  Future<void> _handleVideoCall() async {
    final selectedPet = ref.read(selectedPetProvider);

    if (selectedPet == null) {
      _showError('통화할 어르신을 먼저 선택해주세요');
      return;
    }

    _logger.info('통화 시작: ${selectedPet.petName} (${selectedPet.petId})');

    try {
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
              color: const Color(0xFF6A85B6),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 100.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: AppLayout.topSectionGap),
                    _buildSectionHeader("어르신 선택", "보호 중인 어르신 목록이에요"),
                    _buildCareSelectionRow(hasSelectedPet),
                    SizedBox(height: 32.h),
                    _buildSectionHeader("실시간 상태", "어르신이 안전하게 계신지 확인하세요"),
                    const StatusCard(), // forceWarning 제거 (서버 연동 시)
                    SizedBox(height: 32.h),
                    const LatestAccidentBanner(),
                    SizedBox(height: 32.h),
                    const RobotSection(),
                    SizedBox(height: 32.h),
                    _buildSectionHeader("오늘의 일정", "예정된 주요 일과들이에요"),
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

  // ... Widget Builders (기존 코드와 동일)
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

  Widget _buildCareSelectionRow(bool hasSelectedPet) {
    return Row(
      children: [
        const Expanded(child: CareDropdown()),
        SizedBox(width: 8.w),
        _buildVideoCallButton(hasSelectedPet),
      ],
    );
  }

  Widget _buildVideoCallButton(bool enabled) {
    return SizedBox(
      width: 40.w,
      height: 40.h,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? NoIllColors.primary : Colors.grey.shade300,
          foregroundColor: enabled ? Colors.white : Colors.grey.shade500,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: enabled ? 2 : 0,
          padding: EdgeInsets.zero,
          disabledBackgroundColor: Colors.grey.shade300,
          disabledForegroundColor: Colors.grey.shade500,
        ),
        onPressed: enabled ? _handleVideoCall : null,
        child: Center(child: Icon(Icons.videocam_rounded, size: 28.sp)),
      ),
    );
  }
}
