package com.noill.domain.pet.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
@Schema(description = "로봇펫 인증 응답")
public class PetVerifyResponse {
    @Schema(description = "펫 고유 번호", example = "1")
    private Long petNo;
    @Schema(description = "펫 일련번호", example = "PET001")
    private String petId;
    @Schema(description = "펫 이름", example = "김영수")
    private String petName;
}
