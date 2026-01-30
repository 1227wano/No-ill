class FallEvent {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final DateTime detectedAt;

  FallEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.detectedAt,
  });

  // JSON 데이터를 객체로 변환
  factory FallEvent.fromJson(Map<String, dynamic> json) {
    return FallEvent(
      id: json['id'].toString(),
      title: json['title'] ?? '낙상 감지',
      description: json['description'] ?? '',
      imageUrl: json['file'] ?? '', // 백엔드와 약속한 'file' 키값 사용
      detectedAt: DateTime.parse(json['createdAt']),
    );
  }
}
