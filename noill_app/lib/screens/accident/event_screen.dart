import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/event_provider.dart';
import '../../models/event_models.dart';

class EventScreen extends ConsumerWidget {
  const EventScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. 💡 이전 화면(목록)에서 넘겨준 petId와 careName을 안전하게 추출합니다.
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final String petId = args['petId'] ?? "";
    final String careName = args['careName'] ?? "어르신";

    // 2. 💡 전체가 아닌 '특정 petId' 전용 프로바이더(.family)를 구독합니다.
    final reportsAsync = ref.watch(singlePetReportProvider(petId));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          "$careName 어르신 상세 보고서", // 💡 성함을 동적으로 표시합니다.
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: reportsAsync.when(
        data: (reports) {
          if (reports.isEmpty) {
            return const Center(child: Text("기록된 사고 보고서가 없습니다."));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: reports.length,
            // 💡 카드 생성 시 careName을 함께 전달합니다.
            itemBuilder: (context, index) =>
                _buildReportCard(reports[index], careName),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("데이터를 불러오지 못했습니다: $err")),
      ),
    );
  }

  // 💡 가독성을 위해 careName을 인자로 받도록 수정했습니다.
  Widget _buildReportCard(EventModel report, String careName) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (report.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
              child: CachedNetworkImage(
                imageUrl: report.imageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    Container(height: 200, color: Colors.grey[200]),
                errorWidget: (context, url, error) =>
                    const Icon(Icons.broken_image, size: 50),
              ),
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
                      "$careName $careName - ${report.title}", // 💡 어르신 이름 반영
                      style: const TextStyle(
                        fontSize: 17,
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
                const SizedBox(height: 10),
                Text(
                  report.body,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
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
