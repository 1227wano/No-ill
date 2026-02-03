class ScheduleModel {
  final int? id;
  final int petNo;
  final String schName;
  final DateTime schTime;
  final String? schMemo;
  final String? schStatus; // ✅ 서버에서 주는 값 (예: "PENDING", "DONE")

  ScheduleModel({
    this.id,
    required this.petNo,
    required this.schName,
    required this.schTime,
    this.schMemo,
    this.schStatus,
  });

  // 1. 💡 서버 시간(UTC)을 로컬 시간(한국)으로 자동 변환
  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      id: json['id'],
      petNo: json['petNo'],
      schName: json['schName'],
      // .toLocal()을 붙여야 9시간 차이가 나지 않습니다.
      schTime: DateTime.parse(json['schTime']).toLocal(),
      schMemo: json['schMemo'],
      schStatus: json['schStatus'],
    );
  }

  // 2. 💡 등록(POST) 명세에 맞춰 petNo는 제외하고 petId만 포함
  Map<String, dynamic> toJson(String petId) {
    return {
      "schName": schName,
      "schTime": schTime.toUtc().toIso8601String(), // 서버로는 UTC로 보냄
      "petId": petId,
      "schMemo": schMemo ?? "",
    };
  }

  // 기존 로직 유지
  bool get isPassed => schStatus == "DONE" || schTime.isBefore(DateTime.now());
}
