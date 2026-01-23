package com.noill.schedule.dto;

import com.noill.schedule.entity.Schedule;
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

    private String schMemo;

    public Schedule toEntity(com.noill.domain.user.entity.User user) {
        Schedule schedule = new Schedule();
        schedule.setUser(user);
        schedule.setSchName(this.schName);
        schedule.setSchTime(this.schTime);
        schedule.setSchMemo(this.schMemo);
        return schedule;
    }
}
