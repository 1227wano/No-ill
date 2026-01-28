package com.noill.domain.conversation.service;

import com.noill.domain.conversation.dto.LlmAnalysisResult;
import com.noill.domain.conversation.dto.LlmIntent;
import com.noill.domain.conversation.dto.TalkResponseDto;
import com.noill.domain.pet.entity.Pet;
import com.noill.domain.pet.repository.PetRepository;
import com.noill.domain.schedule.service.ScheduleService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Slf4j
@Service
@RequiredArgsConstructor
public class RobotInteractionService {

    private final LlmService llmService;
    private final ScheduleService scheduleService;
    private final PetRepository petRepository;

    /**
     * 로봇(클라이언트)의 음성/텍스트 요청을 처리하는 진입점
     * 
     * @param userText 사용자 발화 텍스트
     * @param petNo    반려동물 식별 번호
     * @return 로봇이 취할 행동 및 TTS 답변
     */
    @Transactional
    public TalkResponseDto handleUserRequest(String userText, Long petNo) {
        log.info("Robot Request: petNo={}, text={}", petNo, userText);

        // 1. Pet 검증 (단순 조회)
        // TODO: 추후 PetQueryService 등을 통해 공통 검증 로직으로 대체 가능
        Pet pet = petRepository.findById(petNo)
                .orElseThrow(() -> new IllegalArgumentException("해당 반려동물을 찾을 수 없습니다. petNo=" + petNo));

        // 2. LLM 의도 분석
        LlmAnalysisResult analysis = llmService.analyzeUserCommand(userText);
        log.info("Analysis Result: intent={}", analysis.getIntent());

        // 3. 의도에 따른 분기 처리 (Routing)
        String ttsReply = analysis.getContent();
        String actionCode = "NONE";

        if (analysis.getIntent() == LlmIntent.SCHEDULE && analysis.getScheduleData() != null) {
            // 일정 등록 서비스 호출
            // ScheduleService.addScheduleFromLlm은 내부적으로 예외 발생 시 에러 메시지 String을 반환함
            ttsReply = scheduleService.addScheduleFromLlm(analysis.getScheduleData(), pet, analysis.getContent());
            actionCode = "SCHEDULE_ADDED";

        } else if (analysis.getIntent() == LlmIntent.DAILY_TALK) {
            // TODO: 대화 저장 로직 (TalkService) 호출 필요
            // 현재는 로그만 남기고 통과
            log.info("Saving daily conversation (Not implemented yet)");
            actionCode = "NONE";
        }

        // 4. 결과 반환
        return TalkResponseDto.builder()
                .reply(ttsReply)
                .action(actionCode)
                .build();
    }
}
