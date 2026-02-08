package com.noill.domain.schedule.dto;

import com.noill.domain.schedule.entity.Schedule;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Getter;
import java.time.LocalDateTime;

/**
 * ScheduleResponseDto
 * Entity 패키지 변경 반영
 */
@Getter
@Schema(description = "일정 응답")
public class ScheduleResponseDto {
    @Schema(description = "일정 ID", example = "1")
    private Long id;
    @Schema(description = "펫 고유 번호", example = "1")
    private Long petNo;
    @Schema(description = "일정 이름", example = "병원 방문")
    private String schName;
    @Schema(description = "일정 시간", example = "2025-02-10T10:00:00")
    private LocalDateTime schTime;
    @Schema(description = "일정 메모", example = "내과 정기 검진")
    private String schMemo;
    @Schema(description = "일정 상태", example = "PENDING")
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
