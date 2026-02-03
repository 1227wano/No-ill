// 선택된 어르신의 개별 사고기록을 보는 화면

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/event_provider.dart';

class EventScreen extends ConsumerWidget {
  const EventScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Navigator를 통해 전달받은 인자(petId, careName) 추출
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final String petId = args['petId'];
    final String careName = args['careName'];

    // 2. 해당 어르신의 전용 프로바이더 구독
    final reportsAsync = ref.watch(singlePetReportProvider(petId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(title: Text("$careName 어르신 보고서"), centerTitle: true),
      body: reportsAsync.when(
        data: (reports) {
          if (reports.isEmpty) {
            return const Center(child: Text("기록된 사고 보고서가 없습니다."));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: reports.length,
            itemBuilder: (context, index) =>
                _buildReportCard(reports[index], careName),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("에러가 발생했습니다: $err")),
      ),
    );
  }

  Widget _buildReportCard(dynamic report, String careName) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🖼️ 서버에서 준 이미지가 있다면 표시
          if (report.imageUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl: report.imageUrl,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: Colors.grey[200]),
              errorWidget: (context, url, error) =>
                  const Icon(Icons.broken_image, size: 50),
            ),

          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      report.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                    Text(
                      report.formattedTime,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  report.body,
                  style: const TextStyle(fontSize: 15, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
