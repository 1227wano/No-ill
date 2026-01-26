package com.noill.domain.robot.dto;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class RobotStatusRequestDto {
    private String status; // "PATROL", "TRACK"
}
