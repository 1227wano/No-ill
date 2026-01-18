package com.noill.domain.user.service;

import com.noill.domain.user.dto.LoginRequest;
import com.noill.domain.user.dto.LoginResponse;
import com.noill.domain.user.dto.SignupRequest;
import com.noill.domain.user.entity.User;
import com.noill.domain.user.repository.UserRepository;
import com.noill.global.exception.CustomException;
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

    @Transactional
    public void signup(SignupRequest request) {
        if (userRepository.existsByUsername(request.getUsername())) {
            throw CustomException.conflict("이미 사용 중인 아이디입니다");
        }

        User user = User.builder()
                .username(request.getUsername())
                .password(passwordEncoder.encode(request.getPassword()))
                .name(request.getName())
                .address(request.getAddress())
                .phone(request.getPhone())
                .emergencyPhone(request.getEmergencyPhone())
                .build();

        userRepository.save(user);
    }

    @Transactional(readOnly = true)
    public LoginResponse login(LoginRequest request) {
        Authentication authentication = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(request.getUsername(), request.getPassword())
        );

        String token = jwtTokenProvider.generateToken(authentication);
        return LoginResponse.of(token, jwtTokenProvider.getExpiration());
    }
}
