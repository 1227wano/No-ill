package com.noill.domain.pet.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor
@Schema(description = "로봇펫 FCM 토큰 등록 요청")
public class PetFcmTokenRequest {

    @Schema(description = "FCM 토큰", example = "dGVzdF90b2tlbl92YWx1ZQ...")
    @NotBlank(message = "FCM 토큰은 필수입니다.")
    private String fcmToken;
}
