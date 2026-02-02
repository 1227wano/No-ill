class FallEvent {
  final int eventNo; // DB: event_no
  final int petNo; // DB: pet_no (이제 파일명이 아닌 이 숫자로 구분합니다)
  final DateTime eventTime; // DB: event_time
  final String? imageUrl;
  final String title;
  final String description;

  FallEvent({
    required this.eventNo,
    required this.petNo,
    required this.eventTime,
    this.imageUrl,
    this.title = "낙상 사고 감지",
    this.description = "기기에서 낙상 의심 상황을 감지하여 알림을 전송했습니다.",
  });

  factory FallEvent.fromJson(Map<String, dynamic> json) {
    return FallEvent(
      // 💡 파일명이 아닌 JSON의 'pet_no' 필드를 직접 읽습니다.
      eventNo: json['event_no'] ?? json['EVENT_NO'] ?? 0,
      petNo: json['pet_no'] ?? json['PET_NO'] ?? 0,
      eventTime: json['event_time'] != null
          ? DateTime.parse(json['event_time'])
          : DateTime.now(),
      imageUrl: json['image_url'] ?? json['IMAGE_URL'],
    );
  }
}
