package com.noill.domain.conversation.service;

import com.noill.domain.conversation.entity.Talk;
import com.noill.domain.conversation.repository.TalkRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class ConversationBatchService {

    private final TalkRepository talkRepository;
    private final ConversationService conversationService;
    private final LlmService llmService;

    /**
     * [스케줄러] 만료된 세션 종료 및 요약 (매시 정각 실행)
     * 대상: Status='Y' AND 마지막 메시지로부터 3시간 경과
     * 트랜잭션: 전체에 걸지 않음 (LLM 지연 회피 & 개별 실패 허용)
     */
    @Scheduled(cron = "0 0 * * * *")
    public void closeExpiredSessions() {
        LocalDateTime threshold = LocalDateTime.now().minusHours(3);
        log.info("[Batch] 세션 종료 배치 시작. 기준 시각: {}", threshold);

        // 1. 대상 조회 (Status='Y' & 3시간 경과)
        List<Talk> targetSessions = talkRepository.findTalksWithoutRecentMessages("Y", threshold);
        log.info("[Batch] 종료 대상 세션 수: {}", targetSessions.size());

        if (targetSessions.isEmpty()) {
            return;
        }

        // 2. 순차 처리 (개별 Try-Catch)
        for (Talk talk : targetSessions) {
            try {
                processSingleSession(talk);
            } catch (Exception e) {
                log.error("[Batch] 세션 종료 실패 (TalkNo: {})", talk.getTalkNo(), e);
            }
        }

        log.info("[Batch] 세션 종료 배치 완료.");
    }

    /**
     * 개별 세션 처리 (LLM 요약 -> DB 업데이트)
     * 구조: Read(Tx) -> LLM(No Tx) -> Write(New Tx)
     */
    private void processSingleSession(Talk talk) {
        // Step 1: 전체 대화 내용 조회 (ReadOnly)
        // 이미 1차 캐시에 있을 수 있으나, 확실히 전체를 가져오기 위해 서비스 호출
        String fullContext = conversationService.getConversationFullContext(talk);

        // 대화가 없는 빈 세션의 경우 요약 생략하고 바로 닫음
        if (fullContext == null || fullContext.isEmpty()) {
            conversationService.closeSessionAndUpdateTitle(talk.getTalkNo(), "대화 내용 없음");
            return;
        }

        // Step 2: LLM 요약 요청 (DB Transaction 바깥에서 실행 - Latency 구간)
        // 제목이 너무 길지 않게 50자 제한은 프롬프트에 명시됨
        String summaryTitle = llmService.generateSessionTitle(fullContext);
        log.debug("LLM Summary Generated: {} -> {}", talk.getTalkNo(), summaryTitle);

        // Step 3: DB 업데이트 (ConversationService의 REQUIRES_NEW 메서드 호출)
        conversationService.closeSessionAndUpdateTitle(talk.getTalkNo(), summaryTitle);
    }
}
