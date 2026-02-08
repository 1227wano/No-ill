class PetModel {
  final int? petNo;
  final String petId;
  final String petName;
  final String petAddress;
  final String petPhone;
  final String careName;
  final String petBirth;

  PetModel({
    this.petNo,
    required this.petId,
    this.petName = '노일이',
    this.petAddress = '',
    this.petPhone = '',
    this.careName = '',
    String? petBirth,
  }) : petBirth = petBirth ?? _getTodayDate();

  static String _getTodayDate() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  factory PetModel.fromJson(Map<String, dynamic> json) {
    return PetModel(
      petNo: json['petNo'],
      petId: json['petId'] ?? '',
      petName: json['petName'] ?? '노일이',
      petAddress: json['petAddress'] ?? '',
      petPhone: json['petPhone'] ?? '',
      careName: json['careName'] ?? '',
      petBirth: json['petBirth'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    if (petNo != null) "petNo": petNo, // 등록 시에는 null이므로 제외됨
    "petId": petId,
    "petName": petName,
    "petAddress": petAddress,
    "petPhone": petPhone,
    "petBirth": petBirth,
    "careName": careName,
  };

  // ✅ 이 부분이 모델 내부에 있어야 합니다!
  PetModel copyWith({
    int? petNo,
    String? petId,
    String? petName,
    String? petAddress,
    String? petPhone,
    String? careName,
    String? petBirth,
  }) {
    return PetModel(
      // 새로 들어온 값(petNo)이 있으면 그걸 쓰고, 없으면 기존 값(this.petNo)을 유지합니다.
      petNo: petNo ?? this.petNo,
      petId: petId ?? this.petId,
      petName: petName ?? this.petName,
      petAddress: petAddress ?? this.petAddress,
      petPhone: petPhone ?? this.petPhone,
      careName: careName ?? this.careName,
      petBirth: petBirth ?? this.petBirth,
    );
  }
}
