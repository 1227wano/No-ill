package com.noill.domain.conversation.repository;

import com.noill.domain.conversation.entity.Talk;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;
import java.util.Optional;

public interface TalkRepository extends JpaRepository<Talk, Long> {

    // 사용자의 활성화된 최신 세션 조회
    Optional<Talk> findFirstByPet_PetNoAndStatusOrderByCreatedAtDesc(Long petNo, String status);

    // 과거 기억 검색 (제목 키워드 검색, 종료된 세션만 대상)
    List<Talk> findByPet_PetNoAndStatusAndTalkNameContaining(Long petNo, String status, String keyword);

    /**
     * 일정 시간 동안 대화가 없는 활성 세션 조회 (Batch용)
     * 조건: Status = 'Y' AND MAX(Message.createdAt) <= threshold
     */
    @Query("SELECT t FROM Talk t " +
            "JOIN t.messages m " +
            "WHERE t.status = :status " +
            "GROUP BY t " +
            "HAVING MAX(m.createdAt) <= :threshold")
    java.util.List<Talk> findTalksWithoutRecentMessages(
            @org.springframework.data.repository.query.Param("status") String status,
            @org.springframework.data.repository.query.Param("threshold") java.time.LocalDateTime threshold);
}
