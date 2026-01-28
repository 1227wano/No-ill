package com.noill.domain.notification.service;

import com.noill.domain.notification.dto.FcmTokenRequest;
import com.noill.domain.notification.entity.FcmToken;
import com.noill.domain.notification.repository.FcmTokenRepository;
import com.noill.domain.user.entity.User;
import com.noill.domain.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class NotificationService {

    private final FcmTokenRepository fcmTokenRepository;
    private final UserRepository userRepository;

    // 1. 토큰 저장/갱신 (로그인 성공 직후 호출)
    @Transactional
    public void saveToken(Long userNo, FcmTokenRequest request) {
        User user = userRepository.findById(userNo)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));

        fcmTokenRepository.findByToken(request.getToken())
                .ifPresentOrElse(
                        // A. 이미 있는 토큰이면 -> 유저 정보가 맞는지 확인하고 업데이트 (마지막 활동 시간 갱신됨)
                        existingToken -> {
                            if (!existingToken.getUser().getUserNo().equals(userNo)) {
                                existingToken.updateUser(user); // 기기 사용자가 바뀌었으면 주인 변경
                            }
                        },
                        // B. 없는 토큰이면 -> 새로 저장
                        () -> {
                            fcmTokenRepository.save(FcmToken.builder()
                                    .user(user)
                                    .token(request.getToken())
                                    .build());
                        }
                );
    }

    // 2. 토큰 삭제 (로그아웃 시 호출)
    @Transactional
    public void deleteToken(String token) {
        fcmTokenRepository.deleteByToken(token);
    }
}
