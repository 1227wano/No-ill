package com.noill.domain.pet.dto;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class PetLoginResponse {
    private String accessToken;
    private String refreshToken;
    private Long petId;
    private String petNo;
    private String name;
}
