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

  // 💡 [프론트엔드 핵심 로직]
  // 1. 서버 상태가 이미 'DONE'이거나
  // 2. 서버 상태와 상관없이 현재 시간이 일정 시간을 지났다면 '비활성화'로 간주
  bool get isPassed => schStatus == "DONE" || schTime.isBefore(DateTime.now());

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      id: json['id'],
      petNo: json['petNo'],
      schName: json['schName'],
      schTime: DateTime.parse(json['schTime']),
      schMemo: json['schMemo'],
      schStatus: json['schStatus'], // ✅ 서버 응답 매핑
    );
  }

  // ✅ 등록(POST) 시에는 schStatus를 제외하고 보냄 (서버 명세에 맞춰서)
  Map<String, dynamic> toJson(String petId) {
    return {
      "schName": schName,
      "schTime": schTime.toIso8601String(),
      "petId": petId,
      "petNo": petNo,
      "schMemo": schMemo ?? "",
    };
  }
}
