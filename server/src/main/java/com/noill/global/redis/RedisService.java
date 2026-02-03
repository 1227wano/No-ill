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

    // 범용 Key-Value 저장
    public void setValues(String key, String value, long duration) {
        redisTemplate.opsForValue().set(key, value, duration, TimeUnit.MILLISECONDS);
    }

    // 범용 Value 조회 (FCM 토큰 조회용)
    public String getValues(String key) {
        return (String) redisTemplate.opsForValue().get(key);
    }

    // Key 삭제
    public void deleteValues(String key) {
        redisTemplate.delete(key);
    }
}
