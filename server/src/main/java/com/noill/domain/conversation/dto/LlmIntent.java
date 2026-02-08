package com.noill.domain.conversation.dto;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

import java.util.Arrays;

@Getter
@RequiredArgsConstructor
public enum LlmIntent {
    SCHEDULE("add_schedule"),
    DAILY_TALK("daily_talk"),
    UNKNOWN("unknown");

    private final String code;

    public static LlmIntent fromCode(String code) {
        return Arrays.stream(values())
                .filter(intent -> intent.code.equalsIgnoreCase(code))
                .findFirst()
                .orElse(UNKNOWN);
    }
}
