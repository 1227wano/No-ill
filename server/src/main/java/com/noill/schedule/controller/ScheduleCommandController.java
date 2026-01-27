package com.noill.schedule.controller;

import com.noill.domain.user.entity.User;
import com.noill.schedule.dto.ScheduleTextRequestDto;
import com.noill.schedule.service.ScheduleService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * ScheduleCommandController
 * 음성 명령(Command) 처리를 전담하는 컨트롤러입니다.
 * 기존 CRUD API와 분리하여 관리합니다.
 */
@RestController
@RequestMapping("/api/schedules/command")
@RequiredArgsConstructor
public class ScheduleCommandController {

    private final ScheduleService scheduleService;

    @PostMapping
    public ResponseEntity<Map<String, String>> processCommand(
            @RequestBody ScheduleTextRequestDto requestDto,
            @AuthenticationPrincipal User user) {
        // 음성 명령 분석 및 처리 후 LLM이 생성한 응답 메시지 반환
        String resultMessage = scheduleService.processUserCommand(requestDto.getText(), user);

        // 노일이(로봇)는 JSON 응답을 기대하므로 Map으로 감싸서 반환
        // {"message": "네, 내일 오후 2시에 일정을 잡았어요."}
        return ResponseEntity.ok(Map.of("message", resultMessage));
    }
}
