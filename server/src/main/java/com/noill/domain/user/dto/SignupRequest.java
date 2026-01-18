package com.noill.domain.user.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor
public class SignupRequest {

    @NotBlank(message = "아이디는 필수입니다")
    @Size(min = 4, max = 50, message = "아이디는 4자 이상 50자 이하로 입력해주세요")
    private String username;

    @NotBlank(message = "비밀번호는 필수입니다")
    @Size(min = 8, max = 100, message = "비밀번호는 8자 이상 100자 이하로 입력해주세요")
    private String password;

    @NotBlank(message = "이름은 필수입니다")
    @Size(max = 50, message = "이름은 50자 이하로 입력해주세요")
    private String name;

    @Size(max = 255, message = "주소는 255자 이하로 입력해주세요")
    private String address;

    @Size(max = 20, message = "전화번호는 20자 이하로 입력해주세요")
    private String phone;

    @Size(max = 20, message = "비상전화번호는 20자 이하로 입력해주세요")
    private String emergencyPhone;
}
