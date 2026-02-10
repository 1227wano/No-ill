// 실시간 상태 카드 (어르신)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:noill_app/core/constants/color_constants.dart';
import 'package:noill_app/models/event_model.dart';
import 'package:noill_app/providers/care_provider.dart';
import 'package:noill_app/providers/event_provider.dart';

class StatusCard extends ConsumerWidget {
  const StatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCare = ref.watch(selectedPetProvider);
    final reportAsync = selectedCare != null
        ? ref.watch(eventListByPetProvider(selectedCare.petId))
        : const AsyncValue<List<EventModel>>.data([]);

    final bool isWarning = reportAsync.maybeWhen(
      data: (events) {
        if (events.isEmpty) return false;

        // 가장 최근 사고 가져오기 (이미 정렬되어 있다고 가정)
        final latestEvent = events.first;

        // ✨ [수정] 사고 발생 시간이 현재로부터 5분 이내일 때만 경고
        final diff = DateTime.now().difference(latestEvent.eventTime).inMinutes;
        // 🔥 [이거 추가!] "사고 난 지 1분 넘었으면 그냥 무시해" (초록색으로 초기화)
        if (diff > 1) {
          return false; // 👈 여기가 핵심! 강제 안전 처리
        }

        return true; // 1분 이내에 난 사고만 빨간색
      },
      orElse: () => false,
    );
    final String name = selectedCare?.careName ?? "어르신";

    final Color pointColor = isWarning ? Colors.red : NoIllColors.primary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isWarning ? const Color(0xFFFFEBEE) : const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(
              isWarning ? Icons.warning : Icons.health_and_safety,
              color: pointColor,
            ),
          ),
          SizedBox(width: 16.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isWarning ? "STATUS: WARNING" : "STATUS: SAFE",
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w900,
                  color: pointColor.withOpacity(0.7),
                ),
              ),
              Text(
                isWarning ? "$name님 낙상 감지!" : "$name님은 안전합니다.",
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
