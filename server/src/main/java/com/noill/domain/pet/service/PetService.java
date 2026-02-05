package com.noill.domain.pet.service;

import com.noill.domain.care.entity.Care;
import com.noill.domain.care.repository.CareRepository;
import com.noill.domain.pet.dto.PetLoginRequest;
import com.noill.domain.pet.dto.PetLoginResponse;
import com.noill.domain.pet.dto.PetRegisterRequest;
import com.noill.domain.pet.dto.PetResponse;
import com.noill.domain.pet.entity.Pet;
import com.noill.domain.pet.repository.PetRepository;
import com.noill.domain.user.entity.User;
import com.noill.domain.user.repository.UserRepository;
import com.noill.global.redis.RedisService;          // [해제]
import com.noill.global.security.jwt.JwtTokenProvider; // [해제]
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.util.Collections;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
@lombok.extern.slf4j.Slf4j
public class PetService {

    private final PetRepository petRepository;
    private final CareRepository careRepository;
    private final UserRepository userRepository;
    private final JwtTokenProvider jwtTokenProvider;
    private final RedisService redisService;

    // 1. 보호자(User) 기능: 펫 정보 사전 등록
    @Transactional
    public void registerPet(Long userNo, PetRegisterRequest request) {
        User user = userRepository.findById(userNo)
                .orElseThrow(() -> new IllegalArgumentException("회원 정보가 없습니다."));

        // 1-1. 이미 등록된 기기인지 확인
        Pet pet = petRepository.findByPetId(request.getPetId())
                .orElse(null);

        // 1-2. 기기가 없으면 -> 새로 생성
        if (pet == null) {
            pet = Pet.builder()
                    .petId(request.getPetId())
                    .petName(request.getPetName())
                    .petAddress(request.getPetAddress())
                    .petPhone(request.getPetPhone())
                    .petBirth(request.getPetBirth() != null ? request.getPetBirth().atStartOfDay() : null)
                    .build();
            petRepository.save(pet);
        }

        // 1-3. 중복 등록 방지
        if (careRepository.existsByUserAndPet(user, pet)) {
            throw new IllegalStateException("이미 등록된 보호 대상입니다.");
        }

        // 1-4. Care(관계) 생성
        Care care = Care.builder()
                .user(user)
                .pet(pet)
                .careName(request.getCareName())
                .build();

        careRepository.save(care);
    }

    // 2. 기기(Pet) 기능: 일련번호 로그인 및 토큰 발급
    @Transactional
    public PetLoginResponse loginPet(PetLoginRequest request) {
        // 2-1. 일련번호로 기기 조회
        // 보호자가 먼저 등록해두지 않았다면 여기서 예외가 발생하여 로그인이 차단됨 -> 보안 OK
        Pet pet = petRepository.findByPetId(request.getPetId())
                .orElseThrow(() -> new IllegalArgumentException("등록되지 않은 기기입니다. 보호자 앱에서 먼저 등록해주세요."));

        // 2-2. 기기 전용 Authentication 객체 생성
        // Principal: petId (기기 고유번호)
        // Credentials: null (비밀번호 없음)
        // Authority: ROLE_PET (기기 권한)
        Authentication authentication = new UsernamePasswordAuthenticationToken(
                pet.getPetId(),
                null,
                Collections.singletonList(new SimpleGrantedAuthority("ROLE_PET"))
        );

        // 2-3. 토큰 발급
        String accessToken = jwtTokenProvider.generateToken(authentication);
        String refreshToken = jwtTokenProvider.generateRefreshToken(authentication);

        // 2-4. Refresh Token을 Redis에 저장
        long refreshTokenExpiration = jwtTokenProvider.getRefreshTokenValidityInMilliseconds();
        redisService.setRefreshToken(pet.getPetId(), refreshToken, refreshTokenExpiration);

        // FCM 토큰이 요청에 포함되어 있다면 Redis에 저장
        // Key: "FCM:PET:{petId}" / Members: {fcmToken1, fcmToken2, ...} / 기간: 30일
        if (request.getFcmToken() != null && !request.getFcmToken().isBlank()) {
            String fcmKey = "FCM:PET:" + pet.getPetId();
            long duration = Duration.ofDays(30).toMillis(); // 30일 동안 유지

            redisService.addToSetAndExpire(fcmKey, request.getFcmToken(), duration);
            log.info("✅ [Pet 로그인] FCM 토큰(Set) 저장 완료 - petId: {}, key: {}", pet.getPetId(), fcmKey);
        } else {
            log.warn("⚠️ [Pet 로그인] FCM 토큰이 없음 - petId: {}", pet.getPetId());
        }

        // 2-5. 응답 반환
        return PetLoginResponse.builder()
                .petNo(pet.getPetNo())
                .petId(pet.getPetId())
                .petName(pet.getPetName())
                .accessToken(accessToken)
                .refreshToken(refreshToken)
                .build();
    }

    public List<PetResponse> getMyPets(Long userNo) {

        User user = userRepository.findById(userNo)
                .orElseThrow(() -> new IllegalArgumentException("회원 정보가 없습니다."));

        List<Care> cares = careRepository.findByUser(user);

        return cares.stream()
                .map(PetResponse::from)
                .collect(Collectors.toList());
    }

    // Pet FCM 토큰 등록 (별도 API용)
    public void registerPetFcmToken(String petId, String fcmToken) {
        // petId 검증
        petRepository.findByPetId(petId)
                .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 펫입니다: " + petId));

        String fcmKey = "FCM:PET:" + petId;
        long duration = Duration.ofDays(30).toMillis(); // 30일 유지

        redisService.addToSetAndExpire(fcmKey, fcmToken, duration);
        log.info("✅ [Pet FCM 등록] 완료 - petId: {}, key: {}", petId, fcmKey);
    }
}
