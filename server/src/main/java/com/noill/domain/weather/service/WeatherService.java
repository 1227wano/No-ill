package com.noill.domain.weather.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.noill.domain.weather.dto.WeatherResponseDto;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;

@Slf4j
@Service
@RequiredArgsConstructor
public class WeatherService {

    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;

    @Value("${openweathermap.api.key:dummy_key}")
    private String apiKey;

    // 역삼동 좌표 고정
    private static final double LAT = 37.5008;
    private static final double LON = 127.0369;
    private static final String WEATHER_URL = "https://api.openweathermap.org/data/2.5/weather";
    private static final String AIR_POLLUTION_URL = "https://api.openweathermap.org/data/2.5/air_pollution";

    public WeatherResponseDto getCurrentWeather() {
        // 날씨 정보와 대기질 정보를 각각 조회하여 병합
        WeatherResponseDto.WeatherResponseDtoBuilder builder = WeatherResponseDto.builder();

        try {
            // 1. 날씨 API 호출
            String weatherUri = UriComponentsBuilder.fromHttpUrl(WEATHER_URL)
                    .queryParam("lat", LAT)
                    .queryParam("lon", LON)
                    .queryParam("appid", apiKey)
                    .queryParam("units", "metric")
                    .queryParam("lang", "kr")
                    .toUriString();

            String weatherJson = restTemplate.getForObject(weatherUri, String.class);
            parseWeather(weatherJson, builder);

        } catch (Exception e) {
            log.error("날씨 API 호출 실패: {}", e.getMessage());
            builder.temperature("-").description("정보 없음").humidity("-");
        }

        try {
            // 2. 대기질 API 호출 (미세먼지)
            String pollutionUri = UriComponentsBuilder.fromHttpUrl(AIR_POLLUTION_URL)
                    .queryParam("lat", LAT)
                    .queryParam("lon", LON)
                    .queryParam("appid", apiKey)
                    .toUriString();

            String pollutionJson = restTemplate.getForObject(pollutionUri, String.class);
            parsePollution(pollutionJson, builder);

        } catch (Exception e) {
            log.error("대기질 API 호출 실패: {}", e.getMessage());
            builder.pm10("-");
        }

        return builder.build();
    }

    private void parseWeather(String jsonString, WeatherResponseDto.WeatherResponseDtoBuilder builder)
            throws Exception {
        JsonNode root = objectMapper.readTree(jsonString);

        // 온도
        double temp = root.path("main").path("temp").asDouble();
        builder.temperature(String.format("%.1f", temp));

        // 습도
        int humidity = root.path("main").path("humidity").asInt();
        builder.humidity(String.valueOf(humidity));

        // 날씨 상태
        String description = root.path("weather").get(0).path("description").asText();
        builder.description(description);
    }

    private void parsePollution(String jsonString, WeatherResponseDto.WeatherResponseDtoBuilder builder)
            throws Exception {
        JsonNode root = objectMapper.readTree(jsonString);

        // 미세먼지 (PM10)
        // 구조: list[0].components.pm10
        double pm10 = root.path("list").get(0).path("components").path("pm10").asDouble();
        builder.pm10(String.format("%.0f", pm10));
    }
}
