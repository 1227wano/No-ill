import 'dart:core';
// 실시간 사고 감지용 모델

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
    this.body = "어르신의 낙상 의심 상황이 감지되었습니다.",
    this.imageUrl = "",
    required this.petId,
    this.careName = "",
  });

  factory EventModel.fromJson(Map<String, dynamic> json, String petId) {
    // 1. ✅ 방금 성공한 베이스 주소 (포트 8080 포함)
    const String baseUrl = "http://i14a301.p.ssafy.io:8080/images/";

    // 2. eventNo 처리 (FCM 데이터는 String으로 올 수 있으므로 방어 로직 추가)
    final dynamic rawEventNo = json['eventNo'];
    final int eventNo = rawEventNo is int
        ? rawEventNo
        : int.tryParse(rawEventNo?.toString() ?? '0') ?? 0;

    // 3. 이미지 필드 추출 (이미지 주소 키 후보들)
    final String rawImageUrl =
        json['imageUrl'] ?? json['image_url'] ?? json['image'] ?? "";

    return EventModel(
      eventNo: eventNo,
      eventTime: json['eventTime'] != null
          ? DateTime.parse(json['eventTime'])
          : DateTime.now(),
      title: json['title'] ?? "낙상 의심 상황 발생",
      body: json['body'] ?? "어르신의 상태를 확인해 주세요.",
      // 4. ✅ 헬퍼 함수를 통한 주소 완성
      imageUrl: _formatImageUrl(baseUrl, rawImageUrl),
      petId: petId,
    );
  }

  // 🧩 이미지 주소 조립 로직 (검증된 방식)
  static String _formatImageUrl(String baseUrl, String raw) {
    if (raw.isEmpty) return "";
    if (raw.startsWith('http')) return raw; // 이미 풀 주소면 그대로 사용
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
