package com.noill.domain.weather.controller;

import com.noill.domain.weather.dto.WeatherResponseDto;
import com.noill.domain.weather.service.WeatherService;
import lombok.RequiredArgsConstructor;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@Tag(name = "날씨 API", description = "오늘의 날씨 정보를 제공하는 API")
@RestController
@RequestMapping("/api/weather")
@RequiredArgsConstructor
public class WeatherController {

    private final WeatherService weatherService;

    @Operation(summary = "오늘의 날씨 조회", description = "날씨, 기온, 습도, 미세먼지 정보를 반환합니다.")
    @GetMapping("/today")
    public ResponseEntity<WeatherResponseDto> getTodayWeather() {
        WeatherResponseDto response = weatherService.getCurrentWeather();
        return ResponseEntity.ok(response);
    }
}
