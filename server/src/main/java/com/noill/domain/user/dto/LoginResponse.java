package com.noill.domain.user.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
@Schema(description = "로그인 응답")
public class LoginResponse {

    @Schema(description = "액세스 토큰", example = "eyJhbGciOiJIUzI1NiJ9...")
    private String accessToken;
    @Schema(description = "리프레시 토큰", example = "eyJhbGciOiJIUzI1NiJ9...")
    private String refreshToken;
    @Schema(description = "토큰 타입", example = "Bearer")
    private String tokenType;
    @Schema(description = "만료 시간(초)", example = "3600")
    private Long expiresIn;

    @Schema(description = "사용자 이름", example = "홍길동")
    private String userName;

    public static LoginResponse of(String accessToken, String refreshToken, Long expiresIn, String userName) {
        return LoginResponse.builder()
                .accessToken(accessToken)
                .refreshToken(refreshToken)
                .tokenType("Bearer")
                .expiresIn(expiresIn)
                .userName(userName)
                .build();
    }
}
