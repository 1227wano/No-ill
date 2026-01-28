package com.noill.domain.schedule.controller;

import com.noill.domain.schedule.dto.ScheduleRequestDto;
import com.noill.domain.schedule.dto.ScheduleResponseDto;
import com.noill.domain.schedule.service.ScheduleService;
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
public class ScheduleController {

    private final ScheduleService scheduleService;

    // 일정 등록
    @PostMapping
    public ScheduleResponseDto create(
            @AuthenticationPrincipal User user,
            @Valid @RequestBody ScheduleRequestDto requestDto) {
        if (user == null) {
            throw new IllegalArgumentException("로그인 정보가 유효하지 않습니다. (User principal is null)");
        }
        return scheduleService.addSchedule(requestDto, user);
    }

    // 일정 목록 조회
    @GetMapping
    public List<ScheduleResponseDto> list(@RequestParam(required = false) LocalDate date) {
        if (date != null) {
            return scheduleService.findSchedulesByDate(date);
        }
        return scheduleService.findAllSchedules();
    }

    /**
     * 일정 수정
     * [PUT] /api/schedules/{id}
     */
    @PutMapping("/{id}")
    public ScheduleResponseDto update(@PathVariable Long id, @Valid @RequestBody ScheduleRequestDto requestDto) {
        return scheduleService.updateSchedule(id, requestDto);
    }

    /**
     * 일정 삭제
     * [DELETE] /api/schedules/{id}
     * 상태코드 204(No Content) 등을 주거나 200 OK를 줄 수 있습니다.
     */
    @DeleteMapping("/{id}")
    public void delete(@PathVariable Long id) {
        scheduleService.deleteSchedule(id);
    }
}
