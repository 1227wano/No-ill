package com.noill.domain.user.service;

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
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider jwtTokenProvider;
    private final AuthenticationManager authenticationManager;
    private final RedisService redisService;

    @Transactional
    public void signup(SignupRequest request) {
        if (userRepository.existsByUserId(request.getUserId())) {
            throw CustomException.conflict("이미 사용 중인 아이디입니다");
        }

        User user = User.builder()
                .userId(request.getUserId())
                .userPassword(passwordEncoder.encode(request.getUserPassword()))
                .userName(request.getUserName())
                .userAddress(request.getUserAddress())
                .userPhone(request.getUserPhone())
                .userFamilyPhone(request.getUserFamilyPhone())
                .userType(request.getUserType())
                .build();

        userRepository.save(user);
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


        return LoginResponse.of(accessToken, refreshToken, jwtTokenProvider.getExpiration(), user.getUsername(), user.getUserType());
    }

    @Transactional
    public void logout(String accessToken) {
        if (!jwtTokenProvider.validateToken(accessToken)) {
            throw CustomException.badRequest("유효하지 않은 토큰입니다.");
        }

        Authentication authentication = jwtTokenProvider.getAuthentication(accessToken);
        String userId = authentication.getName(); // UserDetails의 username(여기선 userId)

        if (redisService.getRefreshToken(userId) != null) {
            redisService.deleteRefreshToken(userId);
        }

        long remainingTime = jwtTokenProvider.getRemainingExpirationTime(accessToken);
        redisService.setBlackList(accessToken, remainingTime);
    }
}
