package com.noill.global.security;

import com.noill.domain.user.entity.User; // User 엔티티 import 추가
import com.noill.domain.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class CustomUserDetailsService implements UserDetailsService {

    private final UserRepository userRepository;

    @Override
    public UserDetails loadUserByUsername(String userId) throws UsernameNotFoundException {
        return userRepository.findByUserId(userId)
                .orElseThrow(() -> new UsernameNotFoundException("해당 아이디를 가진 회원을 찾을 수 없습니다: " + userId));
    }
}
