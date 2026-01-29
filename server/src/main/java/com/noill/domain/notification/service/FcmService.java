package com.noill.domain.notification.service;

import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

@Service
@Slf4j
public class FcmService {

    // Firebase로 메시지를 전송하는 메서드
    public void sendNotification(String token, String title, String body, MultipartFile file) {
        try {
            // 전송할 메시지 객체 생성
            Message message = Message.builder()
                    .setToken(token)
                    .setNotification(Notification.builder()
                            .setTitle(title)
                            .setBody(body)
                            .setImage(file.getOriginalFilename())
                            .build())
                    .build();

            // Firebase로 전송
            String response = FirebaseMessaging.getInstance().send(message);
            log.info("FCM 전송 성공: 토큰 끝자리={}, 응답ID={}", token.substring(token.length() - 10), response);

        } catch (Exception e) {
            // 토큰이 만료되었거나 오류가 발생해도, 다른 보호자에게는 알림이 가야 하므로 에러를 로그만 남기고 넘깁니다.
            log.warn("FCM 전송 실패: 토큰={}, 에러={}", token, e.getMessage());
        }
    }
}
