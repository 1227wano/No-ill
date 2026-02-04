package com.noill.domain.user.dto;

import com.noill.domain.pet.dto.PetRegisterRequest;
import jakarta.validation.Valid; // 리스트 내부 검증을 위해 필요
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@Schema(description = "회원가입 요청")
public class SignupRequest {

    @Schema(description = "사용자 아이디", example = "guardian01")
    @NotBlank(message = "아이디는 필수입니다")
    @Size(min = 4, max = 50, message = "아이디는 4자 이상 50자 이하로 입력해주세요")
    private String userId;

    @Schema(description = "비밀번호", example = "password123!")
    @NotBlank(message = "비밀번호는 필수입니다")
    @Size(min = 8, max = 50, message = "비밀번호는 8자 이상 50자 이하로 입력해주세요")
    private String userPassword;

    @Schema(description = "사용자 이름", example = "홍길동")
    @NotBlank(message = "이름은 필수입니다")
    @Size(max = 30, message = "이름은 30자 이하로 입력해주세요")
    private String userName;

    @Schema(description = "주소", example = "서울시 강남구")
    @Size(max = 200, message = "주소는 200자 이하로 입력해주세요")
    private String userAddress;

    @Schema(description = "전화번호", example = "010-1234-5678")
    @NotBlank(message = "전화번호는 필수입니다")
    @Size(max = 20, message = "전화번호는 20자 이하로 입력해주세요")
    private String userPhone;

    @Schema(description = "등록할 로봇펫 목록")
    @Valid
    private List<PetRegisterRequest> pets;

}
