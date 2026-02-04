package com.noill.domain.pet.dto;

import com.noill.domain.care.entity.Care;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
@Schema(description = "로봇펫 정보 응답")
public class PetResponse {
    @Schema(description = "펫 고유 번호", example = "1")
    private Long petNo;
    @Schema(description = "펫 일련번호", example = "PET001")
    private String petId;
    @Schema(description = "펫 이름(노인 이름)", example = "김영수")
    private String petName;
    @Schema(description = "주소", example = "서울시 강남구")
    private String petAddress;
    @Schema(description = "전화번호", example = "010-9876-5432")
    private String petPhone;

    @Schema(description = "보호자 관계명", example = "아들")
    private String careName;
    @Schema(description = "돌봄 시작일", example = "2025-01-15")
    private String careStart;

    public static PetResponse from(Care care) {
        return PetResponse.builder()
                .petNo(care.getPet().getPetNo())
                .petId(care.getPet().getPetId())
                .petName(care.getPet().getPetName())
                .petAddress(care.getPet().getPetAddress())
                .petPhone(care.getPet().getPetPhone())
                .careName(care.getCareName())
                .careStart(care.getCareStart().toString())
                .build();
    }
}
