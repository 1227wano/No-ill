package com.noill.domain.weather.dto;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class WeatherResponseDto {
    private String temperature; // 현재 온도 (예: "24.5")
    private String description; // 날씨 설명 (예: "맑음")
    private String humidity; // 습도 (예: "60")
    private String pm10;
}
