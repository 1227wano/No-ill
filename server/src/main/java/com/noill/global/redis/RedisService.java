package com.noill.global.redis;

import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;

import java.util.concurrent.TimeUnit;

@Service
@RequiredArgsConstructor
public class RedisService {

    private final RedisTemplate<String, Object> redisTemplate;

    public void setRefreshToken(String userId, String refreshToken, long duration) {
        redisTemplate.opsForValue().set("RT:" + userId, refreshToken, duration, TimeUnit.MILLISECONDS);
    }

    public String getRefreshToken(String userId) {
        return (String) redisTemplate.opsForValue().get("RT:" + userId);
    }

    public void deleteRefreshToken(String userId) {
        redisTemplate.delete("RT:" + userId);
    }

    public void setBlackList(String accessToken, long duration) {
        redisTemplate.opsForValue().set(accessToken, "logout", duration, TimeUnit.MILLISECONDS);
    }

    public boolean hasKeyBlackList(String accessToken) {
        return Boolean.TRUE.equals(redisTemplate.hasKey(accessToken));
    }
}
