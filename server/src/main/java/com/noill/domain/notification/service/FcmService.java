package com.noill.domain.notification.service;

import com.google.firebase.messaging.AndroidConfig;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

@Service
@Slf4j
public class FcmService {

    public void sendNotification(String token, String title, String body, String imageUrl) {
        try {
            Notification notification = Notification.builder()
                    .setTitle(title)
                    .setBody(body)
                    .setImage(imageUrl)
                    .build();

            // 전송할 메시지 객체 생성
            Message message = Message.builder()
                    .setToken(token)
                    .setNotification(notification)
                    .build();

            // Firebase로 전송
            String response = FirebaseMessaging.getInstance().send(message);

            // 토큰이 너무 짧을 경우를 대비해 안전하게 로깅
            String tokenSuffix = (token != null && token.length() > 10)
                    ? token.substring(token.length() - 10)
                    : token;

        } catch (Exception e) {
            // 실패하더라도 다른 로직에 영향을 주지 않도록 로그만 남김
            log.warn("FCM 전송 실패: 토큰={}, 에러={}", token, e.getMessage());
        }
    }

    // 화상통화 알림 메시지
    public void sendVideoCallWakeUp(String token, String sessionId) {
        // 조용히 데이터를 받아서 -> 앱이 스스로 화면을 켜고 -> 화상통화 수신 화면을 띄운다.
        try {
            // 우선순위를 높여서(Priority.HIGH) 절전모드여도 즉시 깨움
            AndroidConfig androidConfig = AndroidConfig.builder()
                    .setPriority(AndroidConfig.Priority.HIGH)
                    .build();

            // setNotification() 없이 putData()만 사용
            Message message = Message.builder()
                    .setToken(token)
                    .setAndroidConfig(androidConfig)
                    .putData("type", "VIDEO_CALL")
                    .putData("sessionId", sessionId)
                    .build();

            String response = FirebaseMessaging.getInstance().send(message);

        } catch (Exception e) {
            log.warn("화상통화 WakeUp 전송 실패: 토큰={}, 에러={}", token, e.getMessage());
        }
    }
}
