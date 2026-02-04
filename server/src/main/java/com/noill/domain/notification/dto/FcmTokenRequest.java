package com.noill.domain.notification.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor
@Schema(description = "FCM 토큰 요청")
public class FcmTokenRequest {
    @Schema(description = "FCM 디바이스 토큰", example = "dGVzdF90b2tlbl92YWx1ZQ...")
    @NotBlank(message = "FCM 토큰은 필수입니다.")
    private String token;
}
