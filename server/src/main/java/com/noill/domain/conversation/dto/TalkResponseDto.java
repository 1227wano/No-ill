package com.noill.domain.conversation.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Schema(description = "대화 응답")
public class TalkResponseDto {
    @Schema(description = "로봇이 말할 텍스트 (TTS)", example = "오늘은 맑고 기온은 24도입니다.")
    private String reply;
}
