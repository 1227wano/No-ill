package com.noill.domain.conversation.service;

import com.noill.domain.conversation.dto.LlmAnalysisResult;
import com.noill.domain.conversation.dto.LlmIntent;
import com.noill.domain.conversation.dto.TalkRequestDto;
import com.noill.domain.conversation.dto.TalkResponseDto;
import com.noill.domain.conversation.entity.Talk;
import com.noill.domain.pet.entity.Pet;
import com.noill.domain.pet.repository.PetRepository;
import com.noill.domain.schedule.service.ScheduleService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

@Slf4j
@Service
@RequiredArgsConstructor
public class RobotInteractionService {

    private final LlmService llmService;
    private final ScheduleService scheduleService;
    private final PetRepository petRepository;
    private final ConversationService conversationService; // 추가

    /**
     * 로봇(클라이언트)의 음성/텍스트 요청을 처리하는 진입점
     *
     * @param request 사용자 발화 텍스트 및 반려동물 식별 번호
     * @return 로봇이 취할 행동 및 TTS 답변
     */
    public TalkResponseDto handleUserRequest(TalkRequestDto request) {
        // [검증]
        Pet pet = petRepository.findByPetId(request.getPetId())
                .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 펫입니다. ID: " + request.getPetId()));

        log.info("Robot Request: petId={}, text={}", request.getPetId(), request.getContent());

        // [Phase 1] 사용자 메시지 저장
        Talk currentTalk = conversationService.saveUserMessage(pet, request.getContent());

        // 대화 문맥 및 기억 조회
        // 1. 현재 세션의 대화 내역(History) 조회
        String historyContext = conversationService.getConversationHistory(currentTalk);
        // 2. 과거 기억(Memory) 키워드 검색
        String memoryContext = conversationService.getRelatedMemories(pet, request.getContent());

        log.debug("Context Injected - History: {}, Memory: {}", historyContext.length(), memoryContext.length());

        // [Phase 2] LLM 분석
        // Context를 포함하여 LLM 호출
        LlmAnalysisResult analysis = llmService.analyzeUserCommand(request.getContent(), historyContext, memoryContext);
        log.info("Analysis Result: intent={}", analysis.getIntent());

        String replyContent = "죄송해요, 처리에 문제가 생겼어요."; // 기본값
        // [Routing] & [Phase 3] 봇 응답 생성 및 저장
        if (analysis.getIntent() == LlmIntent.SCHEDULE && analysis.getScheduleData() != null) {
            // 스케줄 처리
            replyContent = scheduleService.addScheduleFromLlm(analysis.getScheduleData(), pet, analysis.getContent());
        } else {
            // 일상 대화 (또는 UNKNOWN)
            replyContent = (analysis.getContent() != null) ? analysis.getContent() : "네, 알겠어요.";
        }

        // [Phase 3] 봇 메시지 DB 저장
        conversationService.saveBotMessage(currentTalk, replyContent);

        return TalkResponseDto.builder()
                .reply(replyContent)
                .build();
    }
}
