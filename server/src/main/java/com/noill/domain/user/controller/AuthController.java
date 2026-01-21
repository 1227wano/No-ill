package com.noill.domain.user.controller;

import com.noill.common.ApiResponse;
import com.noill.domain.user.dto.LoginRequest;
import com.noill.domain.user.dto.LoginResponse;
import com.noill.domain.user.dto.SignupRequest;
import com.noill.domain.user.service.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.RequestHeader;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    @PostMapping("/signup")
    public ResponseEntity<ApiResponse<Void>> signup(@Valid @RequestBody SignupRequest request) {
        authService.signup(request);
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(ApiResponse.success("회원가입이 완료되었습니다"));
    }

    @PostMapping("/login")
    public ResponseEntity<ApiResponse<LoginResponse>> login(@Valid @RequestBody LoginRequest request) {
        LoginResponse response = authService.login(request);
        return ResponseEntity
                .ok(ApiResponse.success("로그인이 완료되었습니다", response));
    }

    @PostMapping("/logout")
    public ResponseEntity<ApiResponse<Void>> logout(@RequestHeader("Authorization") String accessToken) {
        String token = accessToken.substring(7);

        authService.logout(token);

        return ResponseEntity
                .ok(ApiResponse.success("로그아웃 되었습니다."));
    }
}
