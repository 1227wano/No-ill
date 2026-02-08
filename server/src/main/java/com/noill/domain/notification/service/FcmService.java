package com.noill.domain.notification.service;

import com.google.firebase.messaging.AndroidConfig;
import com.google.firebase.messaging.ApnsConfig;
import com.google.firebase.messaging.Aps;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.FirebaseMessagingException;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import com.google.firebase.messaging.MessagingErrorCode;
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

            Message message = Message.builder()
                    .setToken(token)
                    .setNotification(notification)
                    .build();

            FirebaseMessaging.getInstance().send(message);

        } catch (Exception e) {
            log.warn("FCM 전송 실패: 에러={}", e.getMessage());
        }
    }

    public record SendResult(boolean success, boolean invalidToken, String errorMessage) {
    }

    // 화상통화 알림 메시지
    public SendResult sendVideoCallWakeUp(String token, String sessionId) {
        try {
            AndroidConfig androidConfig = AndroidConfig.builder()
                    .setPriority(AndroidConfig.Priority.HIGH)
                    .build();

            ApnsConfig apnsConfig = ApnsConfig.builder()
                    .putHeader("apns-priority", "10")
                    .setAps(Aps.builder()
                            .setContentAvailable(true)
                            .putCustomData("interruption-level", "critical")
                            .build())
                    .build();

            Message message = Message.builder()
                    .setToken(token)
                    .setAndroidConfig(androidConfig)
                    .setApnsConfig(apnsConfig)
                    .putData("type", "VIDEO_CALL")
                    .putData("sessionId", sessionId)
                    .build();

            String response = FirebaseMessaging.getInstance().send(message);
            log.info("✅ 화상통화 WakeUp FCM 전송 성공: sessionId={}, response={}", sessionId, response);
            return new SendResult(true, false, null);

        } catch (FirebaseMessagingException e) {
            String masked = maskToken(token);

            boolean invalid =
                    e.getMessagingErrorCode() == MessagingErrorCode.UNREGISTERED
                            || e.getMessagingErrorCode() == MessagingErrorCode.INVALID_ARGUMENT;

            log.error("❌ 화상통화 WakeUp 전송 실패: token={}, sessionId={}, firebaseErrorCode={}, 에러={}",
                    masked, sessionId, e.getMessagingErrorCode(), e.getMessage(), e);

            return new SendResult(false, invalid, e.getMessage());

        } catch (Exception e) {
            String masked = maskToken(token);
            log.error("❌ 화상통화 WakeUp 전송 실패: token={}, sessionId={}, 에러={}", masked, sessionId, e.getMessage(), e);
            return new SendResult(false, false, e.getMessage());
        }
    }

    private String maskToken(String token) {
        if (token == null) return "<null>";
        if (token.length() <= 10) return "<token:" + token + ">";
        return "<token:..." + token.substring(token.length() - 10) + ">";
    }
}
