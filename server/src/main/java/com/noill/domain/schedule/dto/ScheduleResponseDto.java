package com.noill.domain.schedule.dto;

import com.noill.domain.schedule.entity.Schedule;
import lombok.Getter;
import java.time.LocalDateTime;

/**
 * ScheduleResponseDto
 * Entity 패키지 변경 반영
 */
@Getter
public class ScheduleResponseDto {
    private Long id;
    private Long petNo;
    private String schName;
    private LocalDateTime schTime;
    private String schMemo;
    private String schStatus;

    public ScheduleResponseDto(Schedule schedule) {
        this.id = schedule.getId();
        this.petNo = schedule.getPet().getPetNo();
        this.schName = schedule.getSchName();
        this.schTime = schedule.getSchTime();
        this.schMemo = schedule.getSchMemo();
        this.schStatus = schedule.getSchStatus();
    }
}
