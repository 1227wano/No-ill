package com.noill.domain.schedule.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import io.swagger.v3.oas.annotations.media.Schema;
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
@JsonIgnoreProperties(ignoreUnknown = true)
@Schema(description = "LLM 일정 분석 결과")
public class ScheduleAnalysisResponseDto {

    @Schema(description = "명령어 객체")
    private Command cmd;
    @Schema(description = "사용자에게 응답할 메시지", example = "내일 오후 2시에 병원 방문 일정을 등록했습니다.")
    private String message;

    @Getter
    @Setter
    @NoArgsConstructor
    @ToString
    @JsonIgnoreProperties(ignoreUnknown = true)
    @Schema(description = "LLM 분석 명령어")
    public static class Command {
        @Schema(description = "명령어 타입", example = "add_schedule")
        private String cmdType;
        @Schema(description = "일정 제목", example = "병원 방문")
        private String title;
        @Schema(description = "일정 시간", example = "2025-02-05T14:00:00")
        private String datetime;
        @Schema(description = "일정 메모", example = "내과 정기 검진")
        private String memo;
    }
}
