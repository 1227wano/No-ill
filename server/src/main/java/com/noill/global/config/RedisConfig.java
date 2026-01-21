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

    // URL 형식과 개별 설정 모두 지원
    @Value("${spring.data.redis.url:#{null}}")
    private String url;

    @Value("${spring.data.redis.host:localhost}")
    private String host;

    @Value("${spring.data.redis.port:6379}")
    private int port;

    @Value("${spring.data.redis.password:}")
    private String password;

    @Bean
    public RedisConnectionFactory redisConnectionFactory() {
        RedisStandaloneConfiguration config;

        // URL이 있으면 URL 파싱해서 사용
        if (url != null && !url.isEmpty()) {
            // redis://:password@host:port 형식 파싱
            String cleanUrl = url.replace("redis://", "");
            String[] parts = cleanUrl.split("@");

            String passwordPart = "";
            String hostPort = cleanUrl;

            if (parts.length == 2) {
                passwordPart = parts[0].replace(":", "");
                hostPort = parts[1];
            }

            String[] hostPortParts = hostPort.split(":");
            String parsedHost = hostPortParts[0];
            int parsedPort = hostPortParts.length > 1 ? Integer.parseInt(hostPortParts[1]) : 6379;

            config = new RedisStandaloneConfiguration(parsedHost, parsedPort);
            if (!passwordPart.isEmpty()) {
                config.setPassword(passwordPart);
            }
        } else {
            // URL이 없으면 개별 설정 사용
            config = new RedisStandaloneConfiguration();
            config.setHostName(host);
            config.setPort(port);
            if (password != null && !password.isEmpty()) {
                config.setPassword(password);
            }
        }

        return new LettuceConnectionFactory(config);
    }

    @Bean
    public RedisTemplate<String, Object> redisTemplate() {
        RedisTemplate<String, Object> redisTemplate = new RedisTemplate<>();
        redisTemplate.setConnectionFactory(redisConnectionFactory());

        redisTemplate.setKeySerializer(new StringRedisSerializer());
        redisTemplate.setValueSerializer(new StringRedisSerializer());

        return redisTemplate;
    }
}
