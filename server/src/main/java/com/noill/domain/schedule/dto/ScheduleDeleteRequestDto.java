package com.noill.domain.schedule.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@Schema(description = "일정 삭제 요청")
public class ScheduleDeleteRequestDto {
    @Schema(description = "로봇펫 일련번호", example = "PET001")
    private String petId;
}
