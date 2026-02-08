package com.noill.domain.conversation.dto;

import lombok.Builder;
import lombok.Getter;
import lombok.ToString;

import java.time.LocalDateTime;

@Getter
@Builder
@ToString
public class LlmAnalysisResult {

    private final LlmIntent intent;
    private final String content; // 로봇이 사용자에게 말할 텍스트 (TTS) - 필수
    private final ScheduleData scheduleData; // 일정 데이터 - 선택 (intent가 SCHEDULE일 때만 존재)

    /**
     * 일정 등록용 데이터 DTO
     */
    @Getter
    @Builder
    @ToString
    public static class ScheduleData {
        private final String schName;
        private final LocalDateTime schTime;
        private final String schMemo;
    }
}
