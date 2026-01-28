package com.noill.domain.conversation.controller;

import com.noill.domain.conversation.dto.TalkRequestDto;
import com.noill.domain.conversation.dto.TalkResponseDto;
import com.noill.domain.conversation.service.RobotInteractionService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@Slf4j
@RestController
@RequestMapping("/api/conversations")
@RequiredArgsConstructor
public class ConversationController {

    private final RobotInteractionService robotInteractionService;

    /**
     * 통합 대화 처리 엔드포인트
     * 로봇(클라이언트)은 이 경로로만 발화를 전송하며, 서버가 의도를 파악하여 처리 후 응답합니다.
     */
    @PostMapping("/talk")
    public ResponseEntity<TalkResponseDto> talk(@RequestBody TalkRequestDto request) {
        // 간단한 유효성 검증
        if (request.getPetNo() == null || request.getContent() == null) {
            return ResponseEntity.badRequest().build();
        }

        TalkResponseDto response = robotInteractionService.handleUserRequest(request.getContent(), request.getPetNo());

        return ResponseEntity.ok(response);
    }
}
