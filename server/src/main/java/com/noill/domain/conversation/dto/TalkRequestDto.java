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
@Schema(description = "대화 요청")
public class TalkRequestDto {
    @Schema(description = "로봇 시리얼 번호", example = "PET001")
    private String petId;
    @Schema(description = "사용자 발화 내용", example = "오늘 날씨 어때?")
    private String content;
}
