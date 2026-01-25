package com.noill.global.websocket;

import com.noill.global.redis.RedisService;
import com.noill.global.security.jwt.JwtTokenProvider;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.server.ServerHttpRequest;
import org.springframework.http.server.ServerHttpResponse;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.socket.WebSocketHandler;
import org.springframework.web.socket.server.HandshakeInterceptor;
import org.springframework.web.util.UriComponentsBuilder;

import java.util.Map;

@Slf4j
@Component
@RequiredArgsConstructor
public class JwtHandshakeInterceptor implements HandshakeInterceptor {

    private final JwtTokenProvider jwtTokenProvider;
    private final RedisService redisService;

    @Override
    public boolean beforeHandshake(ServerHttpRequest request, ServerHttpResponse response,
                                   WebSocketHandler wsHandler, Map<String, Object> attributes) {
        String token = extractToken(request);

        if (!StringUtils.hasText(token)) {
            log.warn("WebSocket handshake failed: No token provided");
            return false;
        }

        if (!jwtTokenProvider.validateToken(token)) {
            log.warn("WebSocket handshake failed: Invalid token");
            return false;
        }

        if (redisService.hasKeyBlackList(token)) {
            log.warn("WebSocket handshake failed: Token is blacklisted");
            return false;
        }

        String username = jwtTokenProvider.getUsernameFromToken(token);
        attributes.put("username", username);
        log.info("WebSocket handshake successful for user: {}", username);

        return true;
    }

    @Override
    public void afterHandshake(ServerHttpRequest request, ServerHttpResponse response,
                               WebSocketHandler wsHandler, Exception exception) {
        // 핸드셰이크 후 처리 (필요 시)
    }

    private String extractToken(ServerHttpRequest request) {
        String query = request.getURI().getQuery();
        if (query != null) {
            Map<String, String> params = UriComponentsBuilder.newInstance()
                    .query(query)
                    .build()
                    .getQueryParams()
                    .toSingleValueMap();
            return params.get("token");
        }
        return null;
    }
}
