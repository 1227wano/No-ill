package com.noill.domain.robot.service;

import com.noill.domain.robot.RobotStatus;
import org.springframework.stereotype.Service;

import java.util.concurrent.atomic.AtomicReference;

@Service
public class RobotStatusService {

    // 단일 로봇 상태 관리 (동시성 안전을 위해 AtomicReference 사용)
    // 기본값: PATROL
    private final AtomicReference<RobotStatus> currentStatus = new AtomicReference<>(RobotStatus.PATROL);

    /**
     * 로봇 상태 조회
     * 
     * @return 현재 상태
     */
    public RobotStatus getRobotStatus() {
        return currentStatus.get();
    }

    /**
     * 로봇 상태 변경 (수동/자동)
     * 
     * @param statusString 변경할 상태 문자열 ("TRACK", "PATROL" 등)
     * @return 변경된 상태
     */
    public RobotStatus updateRobotStatus(String statusString) {
        try {
            // 문자열을 Enum으로 변환 (대소문자 무시)
            RobotStatus newStatus = RobotStatus.valueOf(statusString.toUpperCase());

            // 상태 업데이트 (Atomic하게 값 교체)
            currentStatus.set(newStatus);

            return newStatus;
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException("유효하지 않은 로봇 상태입니다: " + statusString);
        }
    }
}
