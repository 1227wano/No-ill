/// 1. 회원가입 시 포함되는 반려동물 정보 모델
class PetRequest {
  final String petId; // Swagger 명세 기준
  final String petName;
  final String petOwner;
  final String petAddress;
  final String petPhone;
  final String careName;

  PetRequest({
    required this.petId,
    required this.petName,
    required this.petOwner,
    required this.petAddress,
    required this.petPhone,
    required this.careName,
  });

  Map<String, dynamic> toJson() {
    return {
      "petId": petId,
      "petName": petName,
      "petOwner": petOwner,
      "petAddress": petAddress,
      "petPhone": petPhone,
      "careName": careName,
    };
  }
}

/// 2. 회원가입 요청 모델 (SignupRequest)
/// 💡 명세서의 카멜 케이스 필드명과 pets 리스트를 반영했습니다.
class SignupRequest {
  final String userId;
  final String userPassword;
  final String userName;
  final String userAddress;
  final String userPhone;
  final List<PetRequest> pets; // 👈 명세서에 포함된 반려동물 리스트

  SignupRequest({
    required this.userId,
    required this.userPassword,
    required this.userName,
    required this.userAddress,
    required this.userPhone,
    required this.pets,
  });

  Map<String, dynamic> toJson() {
    return {
      "userId": userId, // Swagger: userId
      "userPassword": userPassword, // Swagger: userPassword
      "userName": userName, // Swagger: userName
      "userAddress": userAddress, // Swagger: userAddress
      "userPhone": userPhone, // Swagger: userPhone
      "pets": pets.map((p) => p.toJson()).toList(), // 리스트 변환
    };
  }
}

/// 3. 로그인 응답 모델 (기존 구조 유지)
class LoginResponse {
  final bool success;
  final String message;
  final LoginData? data;

  LoginResponse({required this.success, required this.message, this.data});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'],
      message: json['message'],
      data: json['data'] != null ? LoginData.fromJson(json['data']) : null,
    );
  }
}

class LoginData {
  final String accessToken;
  final String refreshToken;
  final String userName;
  final String userType;

  LoginData({
    required this.accessToken,
    required this.refreshToken,
    required this.userName,
    required this.userType,
  });

  factory LoginData.fromJson(Map<String, dynamic> json) {
    return LoginData(
      accessToken: json['accessToken'] ?? "",
      refreshToken: json['refreshToken'] ?? "",
      userName: json['userName'] ?? "",
      userType: json['userType'] ?? "",
    );
  }
}

/// 4. 공통 응답 모델 (기존 구조 유지)
class CommonResponse {
  final bool success;
  final String message;

  CommonResponse({required this.success, required this.message});

  factory CommonResponse.fromJson(Map<String, dynamic> json) {
    return CommonResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? "",
    );
  }
}
