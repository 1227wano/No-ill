package com.noill.global.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule; // LocalDateTime 처리를 위해 필요
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import com.fasterxml.jackson.databind.SerializationFeature; // import 추가

@Configuration
public class JsonConfig {

    @Bean
    public ObjectMapper objectMapper() {
        ObjectMapper objectMapper = new ObjectMapper();
        objectMapper.registerModule(new JavaTimeModule()); // Java 8 날짜/시간 모듈 등록
        objectMapper.disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS); // 날짜를 배열이 아닌 ISO 문자열로 직렬화
        return objectMapper;
    }
}
