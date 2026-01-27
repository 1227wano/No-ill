package com.noill.schedule.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * ScheduleTextRequestDto
 * 노일이(로봇)로부터 음성 인식된 텍스트를 받는 DTO입니다.
 */
@Getter
@Setter
@NoArgsConstructor
public class ScheduleTextRequestDto {

    @NotBlank(message = "텍스트 입력은 필수입니다.")
    private String text;
}
