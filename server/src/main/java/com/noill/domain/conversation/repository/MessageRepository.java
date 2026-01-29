package com.noill.domain.conversation.repository;

import com.noill.domain.conversation.entity.Message;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface MessageRepository extends JpaRepository<Message, Long> {

    // 해당 세션의 마지막 메시지 조회 (3시간 타임아웃 계산용)
    Optional<Message> findFirstByTalk_TalkNoOrderByCreatedAtDesc(Long talkNo);

    // 해당 세션의 메시지 개수 조회 (Rolling Window 체크용)
    long countByTalk_TalkNo(Long talkNo);

    // 가장 오래된 메시지 2개 조회 (삭제용)
    java.util.List<Message> findTop2ByTalk_TalkNoOrderByCreatedAtAsc(Long talkNo);

    // 최근 메시지 10개 조회 (History 구성용)
    java.util.List<Message> findTop10ByTalk_TalkNoOrderByCreatedAtDesc(Long talkNo);

    // [Batch] 세션 전체 대화 조회 (요약용)
    java.util.List<Message> findAllByTalk_TalkNoOrderByCreatedAtAsc(Long talkNo);
}
