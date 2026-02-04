package com.noill.domain.pet.controller;

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
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@Tag(name = "Pet API", description = "로봇펫 관련 API")
@RestController
@RequiredArgsConstructor
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
}
