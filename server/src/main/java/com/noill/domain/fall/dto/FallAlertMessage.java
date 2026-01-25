package com.noill.domain.fall.dto;

import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;

@Getter
@Builder
public class FallAlertMessage {

    private String type;
    private Long eventId;
    private LocalDateTime detectedAt;
    private String imageBase64;
    private String location;
    private Double confidence;
    private String petName;
    private String message;
}
