package com.noill.domain.conversation.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TalkRequestDto {
    private String petId; // 로봇 시리얼 번호
    private String content; // 사용자 발화 내용
}
