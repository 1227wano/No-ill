package com.noill.domain.weather.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
@Schema(description = "날씨 정보 응답")
public class WeatherResponseDto {
    @Schema(description = "현재 온도", example = "24.5")
    private String temperature;
    @Schema(description = "날씨 설명", example = "맑음")
    private String description;
    @Schema(description = "습도(%)", example = "60")
    private String humidity;
    @Schema(description = "미세먼지(PM10)", example = "35")
    private String pm10;
}
