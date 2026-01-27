package com.noill.domain.pet.dto;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class PetVerifyResponse {
    private Long petNo;
    private String petId;
    private String petName;
}
