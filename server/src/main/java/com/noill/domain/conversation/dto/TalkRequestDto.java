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
    private Long petNo; // 펫 식별 아이디
    private String content; // 사용자 발화 내용
}
