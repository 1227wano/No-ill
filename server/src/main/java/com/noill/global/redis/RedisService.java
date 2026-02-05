package com.noill.global.redis;

import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;

import java.util.Set;
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

    // --- 아래부터: FCM 토큰 다중 저장(Set) 지원 ---

    /**
     * Redis Set에 값을 추가하고 TTL을 duration으로 갱신합니다.
     * - 중복 토큰은 자동으로 제거됨(Set 특성)
     * - 로그인/재등록 시 TTL이 연장되는 효과
     */
    public void addToSetAndExpire(String key, String value, long durationMillis) {
        redisTemplate.opsForSet().add(key, value);
        redisTemplate.expire(key, durationMillis, TimeUnit.MILLISECONDS);
    }

    /**
     * Redis Set의 모든 멤버를 조회합니다.
     */
    public Set<Object> getSetMembers(String key) {
        return redisTemplate.opsForSet().members(key);
    }

    /**
     * Redis Set에서 특정 멤버를 제거합니다.
     */
    public void removeFromSet(String key, String value) {
        redisTemplate.opsForSet().remove(key, value);
    }
}
