package com.noill.domain.robot.dto;

import com.noill.domain.robot.RobotStatus;
import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class RobotStatusResponseDto {
    private RobotStatus status;
}
