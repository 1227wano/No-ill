package com.noill.domain.user.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor
@Schema(description = "로그인 요청")
public class LoginRequest {

    @Schema(description = "사용자 아이디", example = "guardian01")
    @NotBlank(message = "아이디는 필수입니다")
    private String userId;

    @Schema(description = "비밀번호", example = "password123!")
    @NotBlank(message = "비밀번호는 필수입니다")
    private String userPassword;
}
