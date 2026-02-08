package com.noill.domain.schedule.dto;

import io.swagger.v3.oas.annotations.media.Schema;
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
@Schema(description = "음성 인식 텍스트 요청")
public class ScheduleTextRequestDto {

    @Schema(description = "음성 인식된 텍스트", example = "내일 오후 2시에 병원 가야해")
    @NotBlank(message = "텍스트 입력은 필수입니다.")
    private String text;
}
