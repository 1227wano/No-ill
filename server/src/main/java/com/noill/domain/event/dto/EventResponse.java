package com.noill.domain.event.dto;

import com.noill.domain.event.entity.Event;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;

@Getter
@Builder
@Schema(description = "낙상 감지 이벤트 응답")
public class EventResponse {
    @Schema(description = "이벤트 번호", example = "1")
    private Long eventNo;
    @Schema(description = "이벤트 발생 시간", example = "2025-02-04T14:30:00")
    private LocalDateTime eventTime;

    public static EventResponse from(Event event) {
        return EventResponse.builder()
                .eventNo(event.getEventNo())
                .eventTime(event.getEventTime())
                .build();
    }
}
