package com.noill.domain.conversation.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TalkResponseDto {
    private String reply; // 로봇이 말할 텍스트 (TTS)
    private String action; // 클라이언트 수행 동작 (e.g., SCHEDULE_ADDED, NONE)
}
