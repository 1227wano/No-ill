package com.noill.global.redis;

import io.lettuce.core.RedisCommandExecutionException;
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
     * - 기존에 같은 key가 String(Value)로 저장되어 있던 레거시 데이터를 만나면
     *   "읽기(GET) -> 삭제(DEL) -> Set으로 재저장(SADD)"로 자동 마이그레이션합니다.
     */
    public void addToSetAndExpire(String key, String value, long durationMillis) {
        try {
            redisTemplate.opsForSet().add(key, value);
            redisTemplate.expire(key, durationMillis, TimeUnit.MILLISECONDS);
        } catch (Exception e) {
            if (isWrongType(e)) {
                // 레거시(String)로 저장된 값이 있으면 백업해뒀다가 Set으로 옮김
                String legacy = null;
                try {
                    legacy = (String) redisTemplate.opsForValue().get(key);
                } catch (Exception ignore) {
                    // 레거시 값이 Set/Hash 등 다른 타입이면 여기서도 실패할 수 있으니 무시
                }

                redisTemplate.delete(key);

                if (legacy != null && !legacy.isBlank()) {
                    redisTemplate.opsForSet().add(key, legacy);
                }
                redisTemplate.opsForSet().add(key, value);
                redisTemplate.expire(key, durationMillis, TimeUnit.MILLISECONDS);
                return;
            }
            throw e;
        }
    }

    private boolean isWrongType(Throwable t) {
        Throwable cur = t;
        while (cur != null) {
            if (cur instanceof RedisCommandExecutionException ex) {
                String msg = ex.getMessage();
                if (msg != null && msg.contains("WRONGTYPE")) return true;
            }
            cur = cur.getCause();
        }
        return false;
    }

    public Set<Object> getSetMembers(String key) {
        return redisTemplate.opsForSet().members(key);
    }

    public void removeFromSet(String key, String value) {
        redisTemplate.opsForSet().remove(key, value);
    }
}
