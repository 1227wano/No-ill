package com.noill.domain.fall.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor
public class FallEventRequest {

    @NotBlank(message = "이미지는 필수입니다")
    private String imageBase64;

    private String location;

    private Double confidence;
}
