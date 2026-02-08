package com.noill.domain.schedule.dto;

import com.noill.domain.schedule.entity.Schedule;
import com.noill.domain.pet.entity.Pet;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Future;
import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;

/**
 * ScheduleRequestDto
 * Entity 패키지 변경 반영
 */
@Getter
@Setter
@NoArgsConstructor
@Schema(description = "일정 등록/수정 요청")
public class ScheduleRequestDto {

    @Schema(description = "일정 이름", example = "병원 방문")
    @NotBlank(message = "일정 이름은 필수입니다.")
    private String schName;

    @Schema(description = "일정 시간", example = "2025-02-10T10:00:00")
    @Future(message = "일정은 미래 시간이어야 합니다.")
    private LocalDateTime schTime;

    @Schema(description = "로봇펫 일련번호", example = "PET001")
    private String petId;

    @Schema(description = "일정 메모", example = "내과 정기 검진")
    private String schMemo;

    public Schedule toEntity(Pet pet) {
        Schedule schedule = new Schedule();
        schedule.setPet(pet);
        schedule.setSchName(this.schName);
        schedule.setSchTime(this.schTime);
        schedule.setSchMemo(this.schMemo);
        return schedule;
    }
}
