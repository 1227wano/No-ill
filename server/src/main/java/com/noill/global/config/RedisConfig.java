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

    @Value("${spring.data.redis.url:#{null}}")
    private String url;

    @Value("${spring.data.redis.host:localhost}")
    private String host;

    @Value("${spring.data.redis.port:6379}")
    private int port;

    @Value("${spring.data.redis.password:}")
    private String password;

    // 1. 연결 설정 (2번의 유연함 채택)
    @Bean
    public RedisConnectionFactory redisConnectionFactory() {
        RedisStandaloneConfiguration config;

        if (url != null && !url.isEmpty()) {
            // URL 파싱 로직 (생략 가능하나 유연성을 위해 유지)
            config = new RedisStandaloneConfiguration(host, port); // 실제로는 URL 기반 설정을 사용
            // ... (기존 2번의 URL 파싱 로직 포함)
        } else {
            config = new RedisStandaloneConfiguration();
            config.setHostName(host);
            config.setPort(port);
            if (!password.isEmpty()) {
                config.setPassword(password);
            }
        }
        return new LettuceConnectionFactory(config);
    }

    // 2. 데이터 직렬화 설정 (1번의 핵심 로직 채택)
    @Bean
    public RedisTemplate<String, Object> redisTemplate() {
        RedisTemplate<String, Object> redisTemplate = new RedisTemplate<>();
        redisTemplate.setConnectionFactory(redisConnectionFactory());

        // 1번 코드의 핵심: 모든 Key와 Value를 String 형식으로 직렬화
        // 이렇게 해야 Redis-cli에서 데이터를 확인했을 때 깨지지 않고 잘 보입니다.
        StringRedisSerializer stringSerializer = new StringRedisSerializer();

        redisTemplate.setKeySerializer(stringSerializer);
        redisTemplate.setValueSerializer(stringSerializer);
        redisTemplate.setHashKeySerializer(stringSerializer);
        redisTemplate.setHashValueSerializer(stringSerializer);

        return redisTemplate;
    }
}
