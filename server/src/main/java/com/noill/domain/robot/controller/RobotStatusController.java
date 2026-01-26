package com.noill.domain.robot.controller;

import com.noill.domain.robot.RobotStatus;
import com.noill.domain.robot.dto.RobotStatusRequestDto;
import com.noill.domain.robot.dto.RobotStatusResponseDto;
import com.noill.domain.robot.service.RobotStatusService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/robot/status")
@RequiredArgsConstructor
public class RobotStatusController {

    private final RobotStatusService robotStatusService;

    /**
     * 로봇 상태 조회
     * 로봇(클라이언트)이 주기적으로 호출하여 자신의 행동 모드를 결정함.
     */
    @GetMapping
    public ResponseEntity<RobotStatusResponseDto> getStatus() {
        RobotStatus currentStatus = robotStatusService.getRobotStatus();
        return ResponseEntity.ok(new RobotStatusResponseDto(currentStatus));
    }

    /**
     * 로봇 상태 변경 (갱신)
     * 프론트엔드 버튼 클릭 또는 특정 상황 발생 시 호출
     */
    @PostMapping
    public ResponseEntity<RobotStatusResponseDto> updateStatus(@RequestBody RobotStatusRequestDto requestDto) {
        RobotStatus updatedStatus = robotStatusService.updateRobotStatus(requestDto.getStatus());
        return ResponseEntity.ok(new RobotStatusResponseDto(updatedStatus));
    }
}
