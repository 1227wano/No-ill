package com.noill.domain.event.dto;

import com.noill.domain.event.entity.Event;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;

@Getter
@Builder
public class EventResponse {
    private Long eventNo;
    private LocalDateTime eventTime;

    public static EventResponse from(Event event) {
        return EventResponse.builder()
                .eventNo(event.getEventNo())
                .eventTime(event.getEventTime())
                .build();
    }
}
