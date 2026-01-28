package com.noill.domain.user.dto;

import com.noill.domain.pet.dto.PetRegisterRequest;
import jakarta.validation.Valid; // 리스트 내부 검증을 위해 필요
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import java.util.List;

@Getter
@Setter
@NoArgsConstructor
public class SignupRequest {

    @NotBlank(message = "아이디는 필수입니다")
    @Size(min = 4, max = 50, message = "아이디는 4자 이상 50자 이하로 입력해주세요")
    private String userId;

    @NotBlank(message = "비밀번호는 필수입니다")
    @Size(min = 8, max = 50, message = "비밀번호는 8자 이상 50자 이하로 입력해주세요")
    private String userPassword;

    @NotBlank(message = "이름은 필수입니다")
    @Size(max = 30, message = "이름은 30자 이하로 입력해주세요")
    private String userName;

    @Size(max = 200, message = "주소는 200자 이하로 입력해주세요")
    private String userAddress;

    @NotBlank(message = "전화번호는 필수입니다")
    @Size(max = 20, message = "전화번호는 20자 이하로 입력해주세요")
    private String userPhone;

    // @Valid로 @NotBlank 조건도 같이 검사
    @Valid
    private List<PetRegisterRequest> pets;

}
