package com.noill.domain.notification.controller;

import com.noill.domain.care.repository.CareRepository;
import com.noill.domain.notification.dto.FcmTokenRequest;
import com.noill.domain.notification.service.NotificationService;
import com.noill.domain.pet.entity.Pet;
import com.noill.domain.pet.repository.PetRepository;
import com.noill.domain.user.entity.User;
import io.swagger.v3.oas.annotations.Operation;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Slf4j
@RestController
@RequiredArgsConstructor
@RequestMapping("/api/notifications")
public class NotificationController {

    private final NotificationService notificationService;
    private final PetRepository petRepository;
    private final CareRepository careRepository;

    @Operation(summary = "FCM 토큰 등록", description = "로그인 후 호출되어 FCM 토큰 등록")
    @PostMapping("/token")
    public ResponseEntity<Void> registerToken(
            Authentication authentication,
            @RequestBody @Valid FcmTokenRequest request) {

        if (authentication == null || !authentication.isAuthenticated()) {
            log.error("❌ 인증되지 않은 사용자");
            return ResponseEntity.status(401).build();
        }

        Object principal = authentication.getPrincipal();
        log.info("=== FCM 토큰 등록 ===");
        log.info("Principal 타입: {}", principal.getClass().getName());
        log.info("Principal 값: {}", principal);

        List<Long> userNos = extractUserNos(principal);

        if (userNos == null || userNos.isEmpty()) {
            log.error("❌ userNo 추출 실패");
            return ResponseEntity.status(400).build();
        }

        // Pet의 경우 여러 보호자가 있을 수 있으므로 모두 등록
        for (Long userNo : userNos) {
            log.info("FCM 토큰 등록: userNo={}", userNo);
            notificationService.saveToken(userNo, request);
        }

        log.info("✅ FCM 토큰 등록 완료: {} 명의 보호자", userNos.size());

        return ResponseEntity.ok().build();
    }

    /**
     * Principal에서 UserNo 목록 추출
     * - User 로그인: 본인의 userNo 1개
     * - Pet 로그인: 모든 보호자의 userNo 리스트
     */
    private List<Long> extractUserNos(Object principal) {
        if (principal instanceof User) {
            // User 직접 로그인
            User user = (User) principal;
            log.info("✅ User 로그인: userNo={}", user.getUserNo());
            return List.of(user.getUserNo());

        } else if (principal instanceof String) {
            // Pet 로그인 (petId가 String으로 저장됨)
            String petId = (String) principal;
            log.info("⚠️ Pet 로그인: petId={}", petId);

            // Pet 조회
            Pet pet = petRepository.findByPetId(petId)
                    .orElseThrow(() -> new IllegalArgumentException("반려동물을 찾을 수 없습니다: " + petId));

            // Pet의 모든 보호자(User) 조회
            List<Long> userNos = careRepository.findByPet(pet).stream()
                    .map(care -> care.getUser().getUserNo())
                    .toList();

            log.info("✅ Pet 조회 완료: petId={}, 보호자 수={}", petId, userNos.size());
            return userNos;
        }

        log.error("❌ 알 수 없는 Principal 타입: {}", principal.getClass().getName());
        return List.of();
    }

    @Operation(summary = "FCM 토큰 삭제", description = "FCM 토큰 삭제")
    @DeleteMapping("/token")
    public ResponseEntity<Void> removeToken(@RequestBody @Valid FcmTokenRequest request) {
        notificationService.deleteToken(request.getToken());
        return ResponseEntity.ok().build();
    }
}
