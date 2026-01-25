package com.noill.global.websocket;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import com.noill.domain.fall.dto.FallAlertMessage;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

import java.io.IOException;
import java.util.concurrent.ConcurrentHashMap;

@Slf4j
@Component
public class FallAlertWebSocketHandler extends TextWebSocketHandler {

    private final ConcurrentHashMap<String, WebSocketSession> sessions = new ConcurrentHashMap<>();
    private final ObjectMapper objectMapper;

    public FallAlertWebSocketHandler() {
        this.objectMapper = new ObjectMapper();
        this.objectMapper.registerModule(new JavaTimeModule());
    }

    @Override
    public void afterConnectionEstablished(WebSocketSession session) {
        String username = (String) session.getAttributes().get("username");
        sessions.put(session.getId(), session);
        log.info("WebSocket connected: sessionId={}, username={}", session.getId(), username);
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) {
        sessions.remove(session.getId());
        log.info("WebSocket disconnected: sessionId={}, status={}", session.getId(), status);
    }

    @Override
    public void handleTransportError(WebSocketSession session, Throwable exception) {
        log.error("WebSocket transport error: sessionId={}", session.getId(), exception);
        sessions.remove(session.getId());
    }

    public void broadcast(FallAlertMessage message) {
        String jsonMessage;
        try {
            jsonMessage = objectMapper.writeValueAsString(message);
        } catch (IOException e) {
            log.error("Failed to serialize fall alert message", e);
            return;
        }

        TextMessage textMessage = new TextMessage(jsonMessage);

        sessions.values().forEach(session -> {
            if (session.isOpen()) {
                try {
                    session.sendMessage(textMessage);
                    log.info("Fall alert sent to session: {}", session.getId());
                } catch (IOException e) {
                    log.error("Failed to send fall alert to session: {}", session.getId(), e);
                }
            }
        });
    }

    public int getActiveSessionCount() {
        return sessions.size();
    }
}
