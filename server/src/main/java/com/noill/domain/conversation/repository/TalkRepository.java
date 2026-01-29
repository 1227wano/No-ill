package com.noill.domain.conversation.repository;

import com.noill.domain.conversation.entity.Talk;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface TalkRepository extends JpaRepository<Talk, Long> {

    // 특정 펫의 활성화된 최신 세션 조회
    Optional<Talk> findFirstByPet_PetNoAndStatusOrderByCreatedAtDesc(Long petNo, String status);

    // 과거 기억 검색 (제목 키워드 검색, 종료된 세션만 대상)
    List<Talk> findByPet_PetNoAndStatusAndTalkNameContaining(Long petNo, String status, String keyword);
}
