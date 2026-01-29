package com.noill.domain.notification.repository;

import com.noill.domain.notification.entity.FcmToken;
import com.noill.domain.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;

public interface FcmTokenRepository extends JpaRepository<FcmToken, Long> {
    // 토큰 값으로 조회 (이미 등록된 기기인지 확인)
    Optional<FcmToken> findByToken(String token);

    // 특정 유저의 모든 토큰 조회 (알림 보낼 때 사용)
    List<FcmToken> findByUser(User user);

    // 특정 토큰 삭제 (로그아웃 시)
    void deleteByToken(String token);

    // 특정 유저의 토큰 전체 삭제 (회원 탈퇴 시)
    void deleteByUser(User user);
}

