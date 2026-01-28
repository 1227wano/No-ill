package com.noill.domain.conversation.repository;

import com.noill.domain.conversation.entity.Message;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface MessageRepository extends JpaRepository<Message, Long> {

    // 특정 세션의 모든 메시지 시간순 조회 (LLM 컨텍스트용)
    List<Message> findAllByTalk_TalkNoOrderByCreatedAtAsc(Long talkNo);

    // 메시지 개수 확인 (Rolling Window 트리거용)
    long countByTalk_TalkNo(Long talkNo);

    // 가장 오래된 메시지 N개 조회 (삭제 대상 식별용)
    List<Message> findTop2ByTalk_TalkNoOrderByMsgNoAsc(Long talkNo);
}
