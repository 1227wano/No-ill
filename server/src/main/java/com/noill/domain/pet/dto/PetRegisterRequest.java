package com.noill.domain.pet.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import java.time.LocalDate;

@Getter
@Setter
@NoArgsConstructor
public class PetRegisterRequest {
    private String petId;
    private String petName;
    private String petAddress;
    private String petPhone;
    private LocalDate petBirth;

    private String careName;
}
