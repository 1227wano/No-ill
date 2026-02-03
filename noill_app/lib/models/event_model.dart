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
    // 1. ✅ 서버에서 실제로 어떤 데이터가 오는지 콘솔에 찍어 확인합니다.
    print('🔍 서버에서 받은 JSON: $json');

    final int eventNo = json['eventNo'] ?? 0;
    // final String baseUrl = "http://3.123.45.67:8080/images/";
    final String baseUrl = "https://i14a301.p.ssafy.io/images/";

    // 2. ✅ 서버가 주는 이름이 다를 수 있으므로 여러 후보를 체크합니다.
    // imageUrl, image_url, image 중 하나라도 데이터가 있으면 가져옵니다.
    final String rawImageUrl =
        json['imageUrl'] ?? json['image_url'] ?? json['image'] ?? "";

    return EventModel(
      eventNo: eventNo,
      eventTime: DateTime.parse(
        json['eventTime'] ?? DateTime.now().toIso8601String(),
      ),
      title: json['title'] ?? "낙상 의심 상황 발생",
      body: json['body'] ?? "감지 번호 $eventNo: 어르신의 상태를 확인해 주세요.",
      // 3. ✅ 주소가 이미 http로 시작하면 그대로 쓰고, 파일명만 오면 baseUrl을 붙입니다.
      imageUrl: _formatImageUrl(baseUrl, rawImageUrl),
      petId: petId,
    );
  }

  // 이미지 주소 포맷팅을 위한 별도 헬퍼 함수
  static String _formatImageUrl(String baseUrl, String raw) {
    if (raw.isEmpty) return "";
    if (raw.startsWith('http')) return raw; // 이미 풀 주소면 그대로 반환
    return "$baseUrl$raw"; // 파일명만 왔다면 주소 결합
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
