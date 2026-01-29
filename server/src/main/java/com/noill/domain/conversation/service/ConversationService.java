package com.noill.domain.conversation.service;

import com.noill.domain.conversation.entity.Message;
import com.noill.domain.conversation.entity.Talk;
import com.noill.domain.conversation.repository.MessageRepository;
import com.noill.domain.conversation.repository.TalkRepository;
import com.noill.domain.pet.entity.Pet;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.Optional;

@Slf4j
@Service
@RequiredArgsConstructor
public class ConversationService {

    private final TalkRepository talkRepository;
    private final MessageRepository messageRepository;

    private static final int SESSION_TIMEOUT_HOURS = 3;

    /**
     * 현재 유효한 세션(Talk)을 조회하거나 새로 생성합니다.
     * Rule: 마지막 메시지로부터 3시간이 지났으면 기존 세션을 닫고 새로 생성합니다.
     */
    @Transactional
    public Talk getValidTalk(Pet pet) {
        // 1. 해당 펫의 가장 최근 활성 세션 조회
        Optional<Talk> activeTalkOpt = talkRepository.findFirstByPet_PetNoAndStatusOrderByCreatedAtDesc(pet.getPetNo(),
                "Y");

        // 2. 활성 세션이 없으면 무조건 신규 생성
        if (activeTalkOpt.isEmpty()) {
            log.info("활성 세션 없음 -> 신규 생성 (Pet: {})", pet.getPetNo());
            return createNewTalk(pet);
        }

        Talk activeTalk = activeTalkOpt.get();

        // 3. 3시간 룰 체크
        if (isSessionExpired(activeTalk)) {
            log.info("세션 만료 (3시간) -> 기존 Close & 신규 생성 (Talk: {})", activeTalk.getTalkNo());
            activeTalk.close(); // 기존 세션 닫기 (Dirty Checking)
            return createNewTalk(pet);
        }

        // 4. 유효하면 기존 세션 반환
        return activeTalk;
    }

    private boolean isSessionExpired(Talk talk) {
        // 마지막 메시지 조회
        Optional<Message> lastMessageOpt = messageRepository
                .findFirstByTalk_TalkNoOrderByCreatedAtDesc(talk.getTalkNo());

        // 메시지가 하나도 없다면 -> 갓 생성된 세션이므로 만료 아님 (또는 생성일 기준 체크 로직 추가 가능하나 보통 대화 기준)
        if (lastMessageOpt.isEmpty()) {
            // 만약 대화가 없는 빈 세션이 너무 오래 방치된 경우도 처리하고 싶다면 Talk.createdAt을 체크
            // 여기서는 메시지 기준만 적용
            return false;
        }

        LocalDateTime lastMsgTime = lastMessageOpt.get().getCreatedAt();
        long hoursDiff = ChronoUnit.HOURS.between(lastMsgTime, LocalDateTime.now());

        return hoursDiff >= SESSION_TIMEOUT_HOURS;
    }

    private Talk createNewTalk(Pet pet) {
        Talk newTalk = Talk.builder()
                .pet(pet)
                .talkName("새로운 대화") // 초기 제목
                .status("Y")
                .build();
        return talkRepository.save(newTalk);
    }

    // --- Phase 1: 사용자 메시지 저장 (짧은 트랜잭션) ---
    @Transactional
    public Talk saveUserMessage(Pet pet, String userText) {
        // 1. 유효 세션 확보 (3시간 룰 적용)
        Talk talk = getValidTalk(pet);

        // 2. 메시지 저장
        Message message = Message.builder()
                .talk(talk)
                .msgType("Q") // Question (User)
                .msgContent(userText)
                .build();
        messageRepository.save(message);

        return talk;
    }

    // --- Phase 3: 봇 메시지 저장 및 최적화 (짧은 트랜잭션) ---
    @Transactional
    public void saveBotMessage(Talk talk, String botReply) {
        // 1. 메시지 저장
        Message message = Message.builder()
                .talk(talk)
                .msgType("A") // Answer (Bot)
                .msgContent(botReply)
                .build();
        messageRepository.save(message);

        // 2. Rolling Window (오래된 기억망각)
        applyRollingWindowExclusion(talk);
    }

    private void applyRollingWindowExclusion(Talk talk) {
        long count = messageRepository.countByTalk_TalkNo(talk.getTalkNo());
        if (count > 50) {
            // 가장 오래된 2개(Q, A 한 쌍 가정) 조회
            java.util.List<Message> oldMessages = messageRepository
                    .findTop2ByTalk_TalkNoOrderByCreatedAtAsc(talk.getTalkNo());

            // 일괄 삭제 (성능 최적화)
            messageRepository.deleteAll(oldMessages);
            log.info("Rolling Window 동작: 메시지 {}개 삭제 (Talk: {})", oldMessages.size(), talk.getTalkNo());
        }
    }
}
