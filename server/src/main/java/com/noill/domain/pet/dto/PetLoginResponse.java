package com.noill.domain.pet.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
@Schema(description = "로봇펫 연동(로그인) 응답")
public class PetLoginResponse {
    @Schema(description = "액세스 토큰", example = "eyJhbGciOiJIUzI1NiJ9...")
    private String accessToken;
    @Schema(description = "리프레시 토큰", example = "eyJhbGciOiJIUzI1NiJ9...")
    private String refreshToken;
    @Schema(description = "펫 고유 번호", example = "1")
    private Long petNo;
    @Schema(description = "펫 일련번호", example = "PET001")
    private String petId;
    @Schema(description = "펫 이름", example = "김영수")
    private String petName;
}
