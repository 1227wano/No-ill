// API 응답 모델 정의

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
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      userName: json['userName'],
      userType: json['userType'],
    );
  }
}

class SignupRequest {
  final String userId;
  final String userPassword;
  final String userName;
  final String userAddress;
  final String userPhone;

  SignupRequest({
    required this.userId,
    required this.userPassword,
    required this.userName,
    required this.userAddress,
    required this.userPhone,
  });

  Map<String, dynamic> toJson() {
    return {
      "USER_ID": userId,
      "USER_PW": userPassword,
      "USER_NAME": userName,
      "USER_ADDRESS": userAddress,
      "USER_PHONE": userPhone,
    };
  }
}

class CommonResponse {
  final bool success;
  final String message;

  CommonResponse({required this.success, required this.message});

  factory CommonResponse.fromJson(Map<String, dynamic> json) {
    return CommonResponse(success: json['success'], message: json['message']);
  }
}
