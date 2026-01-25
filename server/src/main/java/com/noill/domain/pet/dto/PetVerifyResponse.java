package com.noill.domain.pet.dto;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class PetVerifyResponse {
    private Long petId;
    private String petNo;
    private String name;
}
