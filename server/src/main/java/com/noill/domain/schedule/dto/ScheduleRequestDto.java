package com.noill.domain.schedule.dto;

import com.noill.domain.schedule.entity.Schedule;
import com.noill.domain.pet.entity.Pet;
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
public class ScheduleRequestDto {

    @NotBlank(message = "일정 이름은 필수입니다.")
    private String schName;

    @Future(message = "일정은 미래 시간이어야 합니다.")
    private LocalDateTime schTime;

    private String petId; // 디스플레이 식별자 (필수)

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
