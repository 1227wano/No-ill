package com.noill.domain.user.dto;

import com.noill.domain.user.entity.User.UserType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class SignupRequest {

    @NotBlank(message = "아이디는 필수입니다")
    @Size(min = 4, max = 50, message = "아이디는 4자 이상 50자 이하로 입력해주세요")
    private String userId; // 기존 userId 유지

    @NotBlank(message = "비밀번호는 필수입니다")
    @Size(min = 8, max = 50, message = "비밀번호는 8자 이상 50자 이하로 입력해주세요")
    private String userPassword; // DB 컬럼명 userPassword에 맞춤

    @NotBlank(message = "이름은 필수입니다")
    @Size(max = 30, message = "이름은 30자 이하로 입력해주세요")
    private String userName; // DB 컬럼명 userName에 맞춤

    @Size(max = 200, message = "주소는 200자 이하로 입력해주세요")
    private String userAddress; // address -> userAddress

    @NotBlank(message = "전화번호는 필수입니다")
    @Size(max = 20, message = "전화번호는 20자 이하로 입력해주세요")
    private String userPhone;

    @Size(max = 20, message = "비상전화번호는 20자 이하로 입력해주세요")
    private String userFamilyPhone;

    @NotNull(message = "회원 유형은 필수입니다 (U: 사용자, F: 보호자)")
    private UserType userType;
}
