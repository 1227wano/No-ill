package com.noill.domain.pet.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor
@Schema(description = "로봇펫 연동(로그인) 요청")
public class PetLoginRequest {

    @Schema(description = "로봇펫 일련번호", example = "PET001")
    @NotBlank(message = "로봇펫 일련번호는 필수입니다.")
    @Size(min = 4, message = "로봇펫 번호는 4자 이상이어야 합니다.")
    private String petId;

    @Schema(description = "디스플레이 FCM 토큰", example = "dGVzdF90b2tlbl92YWx1ZQ...")
    private String fcmToken;
}
