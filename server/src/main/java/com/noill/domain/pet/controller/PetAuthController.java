package com.noill.domain.pet.controller;

import com.noill.common.ApiResponse;
import com.noill.domain.pet.dto.PetLoginRequest;
import com.noill.domain.pet.dto.PetLoginResponse;
import com.noill.domain.pet.service.PetAuthService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@Tag(name = "Pet Auth", description = "로봇펫 인증 API")
@RestController
@RequestMapping("/api/auth/pet")
@RequiredArgsConstructor
public class PetAuthController {

    private final PetAuthService petAuthService;

    @Operation(summary = "로봇펫 로그인", description = "로봇펫 번호로 로그인합니다.")
    @PostMapping("/login")
    public ResponseEntity<ApiResponse<PetLoginResponse>> login(
            @Valid @RequestBody PetLoginRequest request) {
        PetLoginResponse response = petAuthService.login(request);
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    @Operation(summary = "로봇펫 로그아웃", description = "로봇펫 로그아웃 처리합니다.")
    @PostMapping("/logout")
    public ResponseEntity<ApiResponse<Void>> logout(
            @RequestHeader("Authorization") String authorization) {
        String accessToken = authorization.replace("Bearer ", "");
        petAuthService.logout(accessToken);
        return ResponseEntity.ok(ApiResponse.success(null));
    }
}
