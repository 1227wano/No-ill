import 'dart:core';

class EventModel {
  final int eventNo;
  final DateTime eventTime;
  final String title;
  final String body;
  final String imageUrl;
  final String petId;
  final String careName;

  EventModel({
    required this.eventNo,
    required this.eventTime,
    this.title = "낙상 사고 발생",
    this.body = "어르신의 낙상 의심 상황이 감지되었습니다. 실시간 영상을 확인해 주세요.",
    this.imageUrl = "",
    required this.petId,
    this.careName = "",
  });

  // 서버 JSON 데이터를 모델로 변환 (Null 방어 로직 포함)
  // factory EventModel.fromJson(Map<String, dynamic> json, String petId) {
  //   return EventModel(
  //     eventNo: json['eventNo'] ?? 0,
  //     eventTime: DateTime.parse(
  //       json['eventTime'] ?? DateTime.now().toIso8601String(),
  //     ),
  //     title: json['title'] ?? "낙상 사고 발생",
  //     body: json['body'] ?? "어르신의 낙상 의심 상황이 감지되었습니다.",
  //     imageUrl: json['imageUrl'] ?? "",
  //     petId: petId,
  //   );
  // }

  factory EventModel.fromJson(Map<String, dynamic> json, String petId) {
    final int eventNo = json['eventNo'] ?? 0;

    // ✅ 이미지 주소를 아예 절대 경로로 고정
    final String baseUrl = "http://3.123.45.67:8080/images/";
    final String rawImageUrl = json['imageUrl'] ?? ""; // 만약 있다면 사용

    return EventModel(
      eventNo: eventNo,
      eventTime: DateTime.parse(
        json['eventTime'] ?? DateTime.now().toIso8601String(),
      ),
      // 데이터가 없을 때를 대비한 기본 문구
      title: json['title'] ?? "낙상 의심 상황 발생",
      body: json['body'] ?? "감지 번호 $eventNo: 어르신의 상태를 확인해 주세요.",
      // 주소가 있으면 붙이고, 없으면 일단 빈 값으로 둡니다.
      imageUrl: rawImageUrl.isNotEmpty ? "$baseUrl$rawImageUrl" : "",
      petId: petId,
    );
  }

  // UI용 시간 포맷팅 게터
  String get formattedTime =>
      "${eventTime.hour.toString().padLeft(2, '0')}:${eventTime.minute.toString().padLeft(2, '0')}";

  // 오늘 발생한 사고인지 확인
  bool get isToday {
    final now = DateTime.now();
    return now.year == eventTime.year &&
        now.month == eventTime.month &&
        now.day == eventTime.day;
  }

  // 어르신 성함을 나중에 입히기 위한 복사 메서드
  EventModel copyWith({String? careName}) {
    return EventModel(
      eventNo: eventNo,
      eventTime: eventTime,
      title: title,
      body: body,
      imageUrl: imageUrl,
      petId: petId,
      careName: careName ?? this.careName,
    );
  }
}
