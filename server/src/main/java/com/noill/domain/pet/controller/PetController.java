package com.noill.domain.pet.controller;

import com.noill.domain.pet.dto.PetFcmTokenRequest;
import com.noill.domain.pet.dto.PetLoginRequest;
import com.noill.domain.pet.dto.PetLoginResponse;
import com.noill.domain.pet.dto.PetRegisterRequest;
import com.noill.domain.pet.dto.PetResponse;
import com.noill.domain.pet.service.PetService;
import com.noill.domain.user.entity.User;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@Tag(name = "Pet API", description = "로봇펫 관련 API")
@RestController
@RequiredArgsConstructor
@Slf4j
public class PetController {

    private final PetService petService;

    @Operation(summary = "로봇펫 등록", description = "보호자의 로봇펫 정보 등록")
    @SecurityRequirement(name = "jwtToken")
    @PostMapping("/api/users/pets")
    public ResponseEntity<Void> registerPet(@AuthenticationPrincipal User user,
            @RequestBody PetRegisterRequest request) {
        petService.registerPet(user.getUserNo(), request);
        return ResponseEntity.ok().build();
    }

    @Operation(summary = "로봇펫 조회", description = "보호자와 연동된 로봇펫 및 노인 정보 목록 조회")
    @SecurityRequirement(name = "jwtToken")
    @GetMapping("/api/users/pets")
    public ResponseEntity<List<PetResponse>> getMyPets(@AuthenticationPrincipal User user) {
        List<PetResponse> response = petService.getMyPets(user.getUserNo());
        return ResponseEntity.ok(response);
    }

    @Operation(summary = "로봇펫 연동", description = "디스플레이에서 일련번호로 로봇펫 연동")
    @PostMapping("/api/auth/pets/login")
    public ResponseEntity<PetLoginResponse> loginPet(@RequestBody @Valid PetLoginRequest request) {
        PetLoginResponse response = petService.loginPet(request);
        return ResponseEntity.ok(response);
    }

    @Operation(summary = "로봇펫 FCM 토큰 등록", description = "로봇펫(디스플레이)의 FCM 토큰을 등록합니다. 영상통화 호출에 사용됩니다.")
    @SecurityRequirement(name = "jwtToken")
    @PostMapping("/api/pets/fcm-token")
    public ResponseEntity<String> registerPetFcmToken(
            Authentication authentication,
            @RequestBody @Valid PetFcmTokenRequest request) {

        if (authentication == null || !authentication.isAuthenticated()) {
            log.error("❌ [Pet FCM] 인증되지 않은 요청");
            return ResponseEntity.status(401).body("인증이 필요합니다.");
        }

        Object principal = authentication.getPrincipal();
        log.info("📱 [Pet FCM] 토큰 등록 요청 - Principal: {}, 타입: {}", principal, principal.getClass().getName());

        // Pet 로그인 시 principal은 petId (String)
        if (!(principal instanceof String)) {
            log.error("❌ [Pet FCM] Pet 전용 API입니다. Principal 타입: {}", principal.getClass().getName());
            return ResponseEntity.status(403).body("Pet 전용 API입니다.");
        }

        String petId = (String) principal;
        petService.registerPetFcmToken(petId, request.getFcmToken());

        log.info("✅ [Pet FCM] 토큰 등록 완료 - petId: {}", petId);
        return ResponseEntity.ok("FCM 토큰이 등록되었습니다.");
    }
}
