package com.noill.domain.schedule.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;

/**
 * ScheduleAnalysisResponseDto
 * LLM(GPT)의 분석 결과를 담는 DTO입니다.
 * JSON 응답을 역직렬화하여 매핑합니다.
 */
@Getter
@Setter
@NoArgsConstructor
@ToString
@JsonIgnoreProperties(ignoreUnknown = true) // LLM이 불필요한 필드를 줄 경우 무시
public class ScheduleAnalysisResponseDto {

    private Command cmd; // 명령어 객체 (중첩 구조)
    private String message; // 사용자에게 응답할 메시지

    @Getter
    @Setter
    @NoArgsConstructor
    @ToString
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Command {
        private String cmdType; // 명령어 타입 (add_schedule, sleep_start 등)
        private String title; // 일정 제목 (add_schedule 시)
        private String datetime; // 일정 시간 (add_schedule 시)
        private String memo; // 일정 메모 (선택사항)

        // 약 관련 필드는 필요 시 추가하거나 ignoreUnknown으로 무시
    }
}
