package com.noill.domain.conversation.controller;

import com.noill.domain.conversation.dto.TalkRequestDto;
import com.noill.domain.conversation.dto.TalkResponseDto;
import com.noill.domain.conversation.service.RobotInteractionService;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import lombok.RequiredArgsConstructor;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@Tag(name = "Conversation API", description = "로봇과 대화를 담당하는 API")
@Slf4j
@RestController
@RequestMapping("/api/conversations")
@RequiredArgsConstructor
@SecurityRequirement(name = "jwtToken") // 클래스 내 모든 API에 자물쇠 아이콘 표시
public class ConversationController {

    private final RobotInteractionService robotInteractionService;

    /**
     * 통합 대화 처리 엔드포인트
     * 로봇(클라이언트)은 이 경로로만 발화를 전송하며, 서버가 의도를 파악하여 처리 후 응답합니다.
     */
    @Operation(summary = "stt로 들어오는 발화 처리", description = "사용자 발화를 분석하고 적절한 응답을 반환합니다.")
    @PostMapping("/talk")
    public ResponseEntity<TalkResponseDto> talk(@RequestBody TalkRequestDto request) {
        // 간단한 유효성 검증
        if (request.getPetId() == null || request.getPetId().isBlank() || request.getContent() == null) {
            return ResponseEntity.badRequest().build();
        }

        TalkResponseDto response = robotInteractionService.handleUserRequest(request);

        return ResponseEntity.ok(response);
    }
}
