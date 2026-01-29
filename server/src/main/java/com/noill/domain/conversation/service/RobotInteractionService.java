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
        // [검증] - TODO: 추후 공통 Validator 등으로 분리 추천
        Pet pet = petRepository.findById(request.getPetNo())
                .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 펫입니다. ID: " + request.getPetNo()));

        log.info("Robot Request: petNo={}, text={}", request.getPetNo(), request.getContent());

        // [Phase 1] 사용자 메시지 저장 (Transaction O)
        Talk currentTalk = conversationService.saveUserMessage(pet, request.getContent());

        // [Phase 2] LLM 분석 (Transaction X - Latency 구간)
        LlmAnalysisResult analysis = llmService.analyzeUserCommand(request.getContent());
        log.info("Analysis Result: intent={}", analysis.getIntent());

        String replyContent = "죄송해요, 처리에 문제가 생겼어요."; // 기본값
        String actionCode = "NONE";

        // [Routing] & [Phase 3] 봇 응답 생성 및 저장 (Transaction O)
        if (analysis.getIntent() == LlmIntent.SCHEDULE && analysis.getScheduleData() != null) {
            // 스케줄 처리
            replyContent = scheduleService.addScheduleFromLlm(analysis.getScheduleData(), pet, analysis.getContent());
            actionCode = "SCHEDULE_ADDED";
        } else {
            // 일상 대화 (또는 UNKNOWN)
            replyContent = (analysis.getContent() != null) ? analysis.getContent() : "네, 알겠어요.";
            actionCode = "NONE";
        }

        // [Phase 3] 봇 메시지 DB 저장
        conversationService.saveBotMessage(currentTalk, replyContent);

        return TalkResponseDto.builder()
                .reply(replyContent)
                .action(actionCode)
                .build();
    }
}
