package com.noill.domain.user.service;

import com.noill.domain.care.entity.Care;
import com.noill.domain.care.repository.CareRepository;
import com.noill.domain.pet.dto.PetRegisterRequest;
import com.noill.domain.pet.entity.Pet;
import com.noill.domain.pet.repository.PetRepository;
import com.noill.domain.user.dto.LoginRequest;
import com.noill.domain.user.dto.LoginResponse;
import com.noill.domain.user.dto.SignupRequest;
import com.noill.domain.user.entity.User;
import com.noill.domain.user.repository.UserRepository;
import com.noill.global.exception.CustomException;
import com.noill.global.redis.RedisService;
import com.noill.global.security.jwt.JwtTokenProvider;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final PetRepository petRepository;
    private final CareRepository careRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider jwtTokenProvider;
    private final AuthenticationManager authenticationManager;
    private final RedisService redisService;

    @Transactional
    public void signup(SignupRequest request) {
        // 1. 중복 아이디 체크
        if (userRepository.existsByUserId(request.getUserId())) {
            throw CustomException.conflict("이미 사용 중인 아이디입니다");
        }

        // 2. User Entity 생성
        User user = User.builder()
                .userId(request.getUserId())
                .userPassword(passwordEncoder.encode(request.getUserPassword()))
                .userName(request.getUserName())
                .userAddress(request.getUserAddress())
                .userPhone(request.getUserPhone())
                .build();

        userRepository.save(user);

        // 3. 펫 정보 저장 로직 (N:M)
        if (request.getPets() != null && !request.getPets().isEmpty()) {
            for (PetRegisterRequest petDto : request.getPets()) {

                // 3-1. 기기(Pet)가 이미 있는지 확인
                Pet pet = petRepository.findByPetId(petDto.getPetId())
                        .orElse(null);

                // 3-2. 없으면 새로 생성
                if (pet == null) {
                    pet = Pet.builder()
                            .petId(petDto.getPetId())
                            .petName(petDto.getPetName())
                            .petAddress(petDto.getPetAddress())
                            .petPhone(petDto.getPetPhone())
                            .build();
                    petRepository.save(pet);
                }

                // 3-3. Care(중간 테이블) 생성 및 저장
                if (!careRepository.existsByUserAndPet(user, pet)) {
                    Care care = Care.builder()
                            .user(user)
                            .pet(pet)
                            .careName(petDto.getCareName())
                            .build();
                    careRepository.save(care);
                }
            }
        }
    }

    @Transactional
    public LoginResponse login(LoginRequest request) {
        Authentication authentication = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(request.getUserId(), request.getUserPassword())
        );

        User user = (User) authentication.getPrincipal();

        String accessToken = jwtTokenProvider.generateToken(authentication);
        String refreshToken = jwtTokenProvider.generateRefreshToken(authentication);

        long refreshTokenExpiration = jwtTokenProvider.getRefreshTokenValidityInMilliseconds();
        redisService.setRefreshToken(user.getUserId(), refreshToken, refreshTokenExpiration);

        return LoginResponse.of(accessToken, refreshToken, jwtTokenProvider.getExpiration(), user.getUsername());
    }

    @Transactional
    public void logout(String accessToken) {
        if (!jwtTokenProvider.validateToken(accessToken)) {
            throw CustomException.badRequest("유효하지 않은 토큰입니다.");
        }

        Authentication authentication = jwtTokenProvider.getAuthentication(accessToken);
        String userId = authentication.getName();

        if (redisService.getRefreshToken(userId) != null) {
            redisService.deleteRefreshToken(userId);
        }

        long remainingTime = jwtTokenProvider.getRemainingExpirationTime(accessToken);
        redisService.setBlackList(accessToken, remainingTime);
    }
}
