class FallEvent {
  final int id;
  final String title; // "낙상 사고 감지"로 고정
  final String description; // 고정된 안내 문구
  final String? imageUrl; // 푸시 알림으로 받은 실시간 이미지 (과거 기록은 null)
  final DateTime detectedAt;

  FallEvent({
    required this.id,
    this.title = "낙상 사고 감지", // 기본값 설정
    this.description = "기기에서 낙상 의심 상황을 감지하여 알림을 전송했습니다.",
    this.imageUrl,
    required this.detectedAt,
  });

  factory FallEvent.fromJson(Map<String, dynamic> json) {
    return FallEvent(
      // ERD의 EVENT_NO와 EVENT_TIME 필드에 맞춤
      id: json['EVENT_NO'] ?? 0,
      detectedAt: json['EVENT_TIME'] != null
          ? DateTime.parse(json['EVENT_TIME'])
          : DateTime.now(),
      // DB에 없는 필드는 생략하거나 null 처리
      imageUrl: json['IMAGE_URL'],
    );
  }
}
