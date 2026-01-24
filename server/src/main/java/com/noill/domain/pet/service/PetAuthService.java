package com.noill.domain.pet.service;

import com.noill.domain.pet.dto.PetLoginRequest;
import com.noill.domain.pet.dto.PetLoginResponse;
import com.noill.domain.pet.dto.PetVerifyResponse;
import com.noill.domain.pet.entity.Pet;
import com.noill.domain.pet.repository.PetRepository;
import com.noill.global.redis.RedisService;
import com.noill.global.security.jwt.JwtTokenProvider;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class PetAuthService {

    private final PetRepository petRepository;
    private final JwtTokenProvider jwtTokenProvider;
    private final RedisService redisService;

    public PetLoginResponse login(PetLoginRequest request) {
        Pet pet = petRepository.findByPetNo(request.getPetNo())
                .orElseThrow(() -> new IllegalArgumentException("등록되지 않은 로봇펫 번호입니다."));

        // Pet용 토큰 생성 (subject를 "pet:{petNo}" 형태로 구분)
        String subject = "pet:" + pet.getPetNo();
        String accessToken = jwtTokenProvider.generateToken(subject);
        String refreshToken = jwtTokenProvider.generateRefreshToken(subject);

        // Refresh Token을 Redis에 저장
        redisService.setRefreshToken(subject, refreshToken,
                jwtTokenProvider.getRefreshTokenValidityInMilliseconds());

        return PetLoginResponse.builder()
                .accessToken(accessToken)
                .refreshToken(refreshToken)
                .petId(pet.getId())
                .petNo(pet.getPetNo())
                .name(pet.getName())
                .build();
    }

    public void logout(String accessToken) {
        String subject = jwtTokenProvider.getUsernameFromToken(accessToken);

        // Redis에서 Refresh Token 삭제
        redisService.deleteRefreshToken(subject);

        // Access Token을 블랙리스트에 추가
        long expiration = jwtTokenProvider.getRemainingExpirationTime(accessToken);
        redisService.setBlackList(accessToken, expiration);
    }

    public PetVerifyResponse verify(String accessToken) {
        // 토큰 유효성 검증
        if (!jwtTokenProvider.validateToken(accessToken)) {
            throw new IllegalArgumentException("유효하지 않은 토큰입니다.");
        }

        // 블랙리스트 확인
        if (redisService.hasKeyBlackList(accessToken)) {
            throw new IllegalArgumentException("로그아웃된 토큰입니다.");
        }

        // 토큰에서 subject 추출 (pet:{petNo} 형식)
        String subject = jwtTokenProvider.getUsernameFromToken(accessToken);
        if (!subject.startsWith("pet:")) {
            throw new IllegalArgumentException("유효하지 않은 Pet 토큰입니다.");
        }

        String petNo = subject.substring(4); // "pet:" 제거
        Pet pet = petRepository.findByPetNo(petNo)
                .orElseThrow(() -> new IllegalArgumentException("등록되지 않은 로봇펫입니다."));

        return PetVerifyResponse.builder()
                .petId(pet.getId())
                .petNo(pet.getPetNo())
                .name(pet.getName())
                .build();
    }
}
