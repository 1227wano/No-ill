package com.noill.domain.pet.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import java.time.LocalDate;

@Getter
@Setter
@NoArgsConstructor
@Schema(description = "로봇펫 등록 요청")
public class PetRegisterRequest {
    @Schema(description = "로봇펫 일련번호", example = "PET001")
    private String petId;
    @Schema(description = "로봇펫 이름(노인 이름)", example = "김영수")
    private String petName;
    @Schema(description = "주소", example = "서울시 강남구")
    private String petAddress;
    @Schema(description = "전화번호", example = "010-9876-5432")
    private String petPhone;
    @Schema(description = "생년월일", example = "1950-03-15")
    private LocalDate petBirth;

    @Schema(description = "보호자 관계명", example = "아들")
    private String careName;
}
