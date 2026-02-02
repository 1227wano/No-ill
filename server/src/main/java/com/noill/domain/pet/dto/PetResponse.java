package com.noill.domain.pet.dto;

import com.noill.domain.care.entity.Care;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class PetResponse {
    private Long petNo;
    private String petId;
    private String petName;
    private String petAddress;
    private String petPhone;

    private String careName;
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
