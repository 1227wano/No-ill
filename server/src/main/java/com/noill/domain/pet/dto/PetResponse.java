package com.noill.domain.pet.dto;

import com.noill.domain.care.entity.Care;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class PetResponse {
    private Long petNo;
    private String petId;
    private String petOwner;

    private String careName;
    private String careStart;

    // Care 엔티티를 받아서 DTO로 변환하는 생성자
    public static PetResponse from(Care care) {
        return PetResponse.builder()
                .petNo(care.getPet().getPetNo())
                .petId(care.getPet().getPetId())
                .petOwner(care.getPet().getPetOwner())
                .careName(care.getCareName())
                .careStart(care.getCareStart().toString())
                .build();
    }
}
