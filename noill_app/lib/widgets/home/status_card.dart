// 실시간 상태 카드 (어르신)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:noill_app/core/constants/color_constants.dart';
import 'package:noill_app/providers/care_provider.dart';
import 'package:noill_app/providers/event_provider.dart';

class StatusCard extends ConsumerWidget {
  const StatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCare = ref.watch(selectedPetProvider);
    final reportAsync = selectedCare != null
        ? ref.watch(singlePetReportProvider(selectedCare.petId))
        : const AsyncValue<List<dynamic>>.data([]);

    final bool isWarning = reportAsync.maybeWhen(
      data: (d) => d.isNotEmpty,
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
