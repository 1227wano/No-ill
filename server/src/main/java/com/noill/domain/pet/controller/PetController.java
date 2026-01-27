package com.noill.domain.pet.controller;

import com.noill.domain.pet.dto.PetLoginRequest;
import com.noill.domain.pet.dto.PetLoginResponse;
import com.noill.domain.pet.dto.PetRegisterRequest;
import com.noill.domain.pet.service.PetService;
import com.noill.domain.user.entity.User;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@Tag(name = "Pet", description = "로봇펫 관련 API")
@RestController
@RequiredArgsConstructor
public class PetController {

    private final PetService petService;

    // [보호자용] 펫 등록 API (User 권한 필요)
    @PostMapping("/api/users/pets")
    public ResponseEntity<Void> registerPet(@AuthenticationPrincipal User user,
                                            @RequestBody PetRegisterRequest request) {
        petService.registerPet(user.getUserNo(), request);
        return ResponseEntity.ok().build();
    }

    // [로봇펫용] 기기 로그인 API (인증 없음, 누구나 호출 가능)
    @PostMapping("/api/auth/pets/login")
    public ResponseEntity<PetLoginResponse> loginPet(@RequestBody @Valid PetLoginRequest request) {
        PetLoginResponse response = petService.loginPet(request);
        return ResponseEntity.ok(response);
    }
}
