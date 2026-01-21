package com.noill.global.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.connection.RedisStandaloneConfiguration;
import org.springframework.data.redis.connection.lettuce.LettuceConnectionFactory;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.serializer.StringRedisSerializer;

@Configuration
public class RedisConfig {

    @Value("${spring.data.redis.host}")
    private String host;

    @Value("${spring.data.redis.port}")
    private int port;

    @Value("${spring.data.redis.password}")
    private String password;

    // 1. Redis 연결 팩토리 생성 (Lettuce 사용)
    @Bean
    public RedisConnectionFactory redisConnectionFactory() {
        // Redis 설정 정보 객체 생성
        RedisStandaloneConfiguration config = new RedisStandaloneConfiguration();
        config.setHostName(host);
        config.setPort(port);
        config.setPassword(password); // 서버에 설정한 비밀번호를 주입!

        return new LettuceConnectionFactory(host, port);
    }

    // 2. RedisTemplate 설정 (여기서 직렬화 방식을 정해줍니다)
    @Bean
    public RedisTemplate<String, Object> redisTemplate() {
        RedisTemplate<String, Object> redisTemplate = new RedisTemplate<>();
        redisTemplate.setConnectionFactory(redisConnectionFactory());

        // Key는 문자열로 저장
        redisTemplate.setKeySerializer(new StringRedisSerializer());

        // Value도 문자열로 저장 (가장 일반적인 설정)
        // 만약 JSON 객체를 그대로 저장하고 싶다면 Jackson2JsonRedisSerializer 등을 사용해야 하지만,
        // 현재 작성하신 코드는 String 위주이므로 StringRedisSerializer가 안전
        redisTemplate.setValueSerializer(new StringRedisSerializer());

        return redisTemplate;
    }
}
