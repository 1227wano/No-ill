class PetRegistrationRequest {
  final String petId; // 기기 일련번호 (5자리)
  final String petName; // 로봇 별명 (기본값: 노일이)
  final String petAddress; // 어르신 거주 주소
  final String petPhone; // 어르신 비상 연락처
  final String careName; // 어르신 성함 (care 테이블용 데이터)

  PetRegistrationRequest({
    this.petId = '',
    this.petName = '노일이',
    this.petAddress = '',
    this.petPhone = '',
    this.careName = '',
  });

  PetRegistrationRequest copyWith({
    String? petId,
    String? petName,
    String? petAddress,
    String? petPhone,
    String? careName,
  }) {
    return PetRegistrationRequest(
      petId: petId ?? this.petId,
      petName: petName ?? this.petName,
      petAddress: petAddress ?? this.petAddress,
      petPhone: petPhone ?? this.petPhone,
      careName: careName ?? this.careName,
    );
  }

  Map<String, dynamic> toJson() => {
    "petId": petId,
    "petName": petName,
    "petAddress": petAddress,
    "petPhone": petPhone,
    "careName": careName,
  };
}
