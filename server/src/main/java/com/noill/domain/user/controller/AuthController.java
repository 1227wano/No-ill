package com.noill.domain.user.controller;

import com.noill.common.ApiResponse;
import com.noill.domain.user.dto.LoginRequest;
import com.noill.domain.user.dto.LoginResponse;
import com.noill.domain.user.dto.SignupRequest;
import com.noill.domain.user.service.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.RequestHeader;

@Tag(name = "Member API", description = "회원 관련 API")
@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    @Operation(summary = "회원 가입", description = "신규 사용자를 등록")
    @PostMapping("/signup")
    public ResponseEntity<ApiResponse<Void>> signup(@Valid @RequestBody SignupRequest request) {
        authService.signup(request);
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(ApiResponse.success("회원가입이 완료되었습니다"));
    }

    @Operation(summary = "로그인", description = "토큰 형식 로그인")
    @PostMapping("/login")
    public ResponseEntity<ApiResponse<LoginResponse>> login(@Valid @RequestBody LoginRequest request) {
        LoginResponse response = authService.login(request);
        return ResponseEntity
                .ok(ApiResponse.success("로그인이 완료되었습니다", response));
    }

    @Operation(summary = "로그아웃", description = "토큰 형식 로그아웃")
    @SecurityRequirement(name = "jwtToken")
    @PostMapping("/logout")
    public ResponseEntity<ApiResponse<Void>> logout(
            @Parameter(description = "Bearer 토큰", example = "Bearer eyJhbGci...")
            @RequestHeader("Authorization") String accessToken) {
        String token = accessToken.substring(7);

        authService.logout(token);

        return ResponseEntity
                .ok(ApiResponse.success("로그아웃 되었습니다."));
    }
}
