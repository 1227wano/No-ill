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

    // --- LLM Context 구성용 메서드 ---

    /**
     * 현재 세션의 대화 내역(History) 반환 (최근 10개)
     * Format:
     * Q: ...
     * A: ...
     */
    @Transactional(readOnly = true)
    public String getConversationHistory(Talk talk) {
        java.util.List<Message> recentMessages = messageRepository
                .findTop10ByTalk_TalkNoOrderByCreatedAtDesc(talk.getTalkNo());

        // 최신순 -> 시간순(과거->현재) 정렬
        java.util.Collections.reverse(recentMessages);

        StringBuilder sb = new StringBuilder();
        for (Message m : recentMessages) {
            sb.append(m.getMsgType().equals("Q") ? "User: " : "Noyle: ");
            sb.append(m.getMsgContent()).append("\n");
        }
        return sb.toString();
    }

    /**
     * [Memory] 과거 기억 키워드 검색
     * - 검색 결과 3개까지 조회 -> "1. 제목\n2. 제목..."
     */
    @Transactional(readOnly = true)
    public String getRelatedMemories(Pet pet, String userText) {
        if (userText == null || userText.length() < 2) {
            return "관련된 과거 기억이 없습니다.";
        }

        // 1. 키워드 추출 (간단히 띄어쓰기 기준 + 2글자 이상)
        // 예: "오늘 병원 갔어" -> "병원"
        String[] words = userText.split("\\s+");
        StringBuilder resultBuilder = new StringBuilder();
        int count = 0;

        for (String word : words) {
            if (word.length() < 2)
                continue;

            // 2. 키워드로 종료된 세션 제목 검색
            java.util.List<Talk> memories = talkRepository.findByPet_PetNoAndStatusAndTalkNameContaining(
                    pet.getPetNo(), "N", word);

            for (Talk memory : memories) {
                if (count >= 3)
                    break; // 최대 3개
                resultBuilder.append("- ").append(memory.getTalkName()).append("\n");
                count++;
            }
            if (count >= 3)
                break;
        }

        return resultBuilder.length() > 0 ? resultBuilder.toString() : "관련된 과거 기억이 없습니다.";
    }

    /**
     * [Batch] 세션 전체 대화 내용 조회 (요약용)
     */
    @Transactional(readOnly = true)
    public String getConversationFullContext(Talk talk) {
        java.util.List<Message> messages = messageRepository.findAllByTalk_TalkNoOrderByCreatedAtAsc(talk.getTalkNo());

        if (messages.isEmpty()) {
            return "";
        }

        StringBuilder sb = new StringBuilder();
        for (Message msg : messages) {
            String role = "Q".equals(msg.getMsgType()) ? "User" : "Noyle";
            sb.append(role).append(": ").append(msg.getMsgContent()).append("\n");
        }
        return sb.toString();
    }

    /**
     * [Batch] 세션 종료 및 제목 업데이트 (별도 트랜잭션)
     * Propagation.REQUIRES_NEW: 배치 처리 중 독립적으로 커밋하기 위함
     */
    @Transactional(propagation = org.springframework.transaction.annotation.Propagation.REQUIRES_NEW)
    public void closeSessionAndUpdateTitle(Long talkNo, String summaryTitle) {
        Talk talk = talkRepository.findById(talkNo)
                .orElseThrow(() -> new IllegalArgumentException("Talk not found: " + talkNo));

        talk.close(summaryTitle);
        // Dirty Checking으로 자동 Update
        log.info("[Batch] 세션 종료 완료: TalkNo={}, Title={}", talkNo, summaryTitle);
    }
}
