package com.noill.domain.notification.controller;

import com.noill.domain.notification.dto.FcmTokenRequest;
import com.noill.domain.notification.service.NotificationService;
import com.noill.domain.user.entity.User;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@Tag(name = "Notification", description = "FCM 알림 관련 API")
@RestController
@RequestMapping("/api/notifications")
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationService notificationService;

    // FCM 토큰 등록 API (로그인 후 호출)
    @PostMapping("/token")
    public ResponseEntity<Void> registerToken(@AuthenticationPrincipal User user,
                                              @RequestBody @Valid FcmTokenRequest request) {
        notificationService.saveToken(user.getUserNo(), request);
        return ResponseEntity.ok().build();
    }

    // FCM 토큰 삭제 API (로그아웃 시 호출)
    @DeleteMapping("/token")
    public ResponseEntity<Void> removeToken(@RequestBody @Valid FcmTokenRequest request) {
        notificationService.deleteToken(request.getToken());
        return ResponseEntity.ok().build();
    }
}
