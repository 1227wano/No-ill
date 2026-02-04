package com.noill.domain.notification.controller;

import com.noill.domain.notification.dto.FcmTokenRequest;
import com.noill.domain.notification.service.NotificationService;
import com.noill.domain.user.entity.User;
import com.noill.domain.user.repository.UserRepository;
import io.swagger.v3.oas.annotations.Operation;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@Slf4j
@RestController
@RequiredArgsConstructor
@RequestMapping("/api/notifications")
public class NotificationController {

    private final NotificationService notificationService;
    private final UserRepository userRepository;

    @Operation(summary = "FCM 토큰 등록", description = "로그인 후 호출되어 FCM 토큰 등록")
    @PostMapping("/token")
    public ResponseEntity<Void> registerToken(
            Authentication authentication,
            @RequestBody @Valid FcmTokenRequest request) {

        if (authentication == null || !authentication.isAuthenticated()) {
            log.error("❌ 인증되지 않은 사용자");
            return ResponseEntity.status(401).build();
        }

        Long userNo = null;
        Object principal = authentication.getPrincipal();

        // UserDetails(User 엔티티) 또는 String(userId) 처리
        if (principal instanceof User) {
            userNo = ((User) principal).getUserNo();
            log.info("✅ User 객체로 인증됨: userNo={}", userNo);
        } else if (principal instanceof String) {
            String userId = (String) principal;
            log.info("⚠️ String으로 인증됨: userId={}", userId);

            User user = userRepository.findByUserId(userId)
                    .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다: " + userId));
            userNo = user.getUserNo();
        } else {
            log.error("❌ 알 수 없는 Principal 타입: {}", principal.getClass().getName());
            return ResponseEntity.status(401).build();
        }

        log.info("FCM 토큰 등록: userNo={}", userNo);
        notificationService.saveToken(userNo, request);

        return ResponseEntity.ok().build();
    }

    @Operation(summary = "FCM 토큰 삭제", description = "FCM 토큰 삭제")
    @DeleteMapping("/token")
    public ResponseEntity<Void> removeToken(@RequestBody @Valid FcmTokenRequest request) {
        notificationService.deleteToken(request.getToken());
        return ResponseEntity.ok().build();
    }
}
