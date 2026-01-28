package com.noill.domain.conversation.repository;

import com.noill.domain.conversation.entity.Talk;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface TalkRepository extends JpaRepository<Talk, Long> {

    // 마지막 활성 세션 조회 (3시간 타임아웃 체크용)
    Optional<Talk> findFirstByPet_PetNoAndStatusOrderByCreatedAtDesc(Long petNo, String status);

    // 과거 기억 검색 (제목 키워드 검색, 종료된 세션만 대상)
    List<Talk> findByPet_PetNoAndStatusAndTalkNameContaining(Long petNo, String status, String keyword);
}
