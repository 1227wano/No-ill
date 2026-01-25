package com.noill.domain.pet.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor
public class PetLoginRequest {

    @NotBlank(message = "로봇펫 번호는 필수입니다.")
    @Size(min = 4, message = "로봇펫 번호는 4자 이상이어야 합니다.")
    private String petNo;
}
