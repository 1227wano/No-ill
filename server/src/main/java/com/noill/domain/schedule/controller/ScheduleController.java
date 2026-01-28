package com.noill.domain.schedule.controller;

import com.noill.domain.schedule.dto.ScheduleRequestDto;
import com.noill.domain.schedule.dto.ScheduleResponseDto;
import com.noill.domain.schedule.service.ScheduleService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import java.time.LocalDate;
import java.util.List;

/**
 * ScheduleController
 * 수정(PUT) 및 삭제(DELETE) API가 추가되었습니다.
 */

import com.noill.domain.user.entity.User;
import org.springframework.security.core.annotation.AuthenticationPrincipal;

@RestController
@RequestMapping("/api/schedules")
@CrossOrigin(origins = "http://localhost:3000") // 이 줄이 있어야 프론트 접근이 가능합니다.
@RequiredArgsConstructor
@Tag(name = "Schedule API", description = "반려동물 일정 관리 API")
public class ScheduleController {

    private final ScheduleService scheduleService;

    @Operation(summary = "일정 등록", description = "새로운 일정을 생성합니다.")
    @PostMapping
    public ScheduleResponseDto create(
            @AuthenticationPrincipal User user,
            @Valid @RequestBody ScheduleRequestDto requestDto) {
        return scheduleService.addSchedule(requestDto, user);
    }

    // 일정 목록 조회 (필수: petNo 또는 petId)
    // 디스플레이는 petId를 주로 사용, 앱은 petNo를 사용할 수 있음.
    @Operation(summary = "일정 목록 조회", description = "특정 반려동물의 일정 목록을 조회합니다. 날짜를 지정하면 해당 날짜의 일정을 조회합니다.")
    @GetMapping
    public List<ScheduleResponseDto> list(
            @AuthenticationPrincipal User user,
            @RequestParam(required = false) Long petNo,
            @RequestParam(required = false) String petId,
            @RequestParam(required = false) LocalDate date) {

        if (date != null) {
            return scheduleService.findSchedulesByDate(petNo, petId, date, user);
        }
        return scheduleService.findAllSchedules(petNo, petId, user);
    }

    /**
     * 일정 수정
     * [PUT] /api/schedules/{id}
     */
    @Operation(summary = "일정 수정", description = "기존 일정을 수정합니다.")
    @PutMapping("/{id}")
    public ScheduleResponseDto update(
            @AuthenticationPrincipal User user,
            @PathVariable Long id,
            @Valid @RequestBody ScheduleRequestDto requestDto) {
        return scheduleService.updateSchedule(id, requestDto, user);
    }

    /**
     * 일정 삭제
     * [DELETE] /api/schedules/{id}
     * Body에 petId 포함
     */
    @Operation(summary = "일정 삭제", description = "일정을 삭제합니다.")
    @DeleteMapping("/{id}")
    public void delete(
            @AuthenticationPrincipal User user,
            @PathVariable Long id,
            @RequestBody ScheduleRequestDto requestDto) {
        scheduleService.deleteSchedule(id, requestDto.getPetNo(), requestDto.getPetId(), user);
    }
}
