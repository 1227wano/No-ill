package com.noill.domain.schedule.controller;

import com.noill.domain.schedule.dto.ScheduleRequestDto;
import com.noill.domain.schedule.dto.ScheduleResponseDto;
import com.noill.domain.schedule.service.ScheduleService;
import com.noill.domain.user.entity.User;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import io.swagger.v3.oas.annotations.security.SecurityRequirement; // 추가
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import com.noill.domain.schedule.dto.ScheduleDeleteRequestDto;

@RestController
@RequestMapping("/api/schedules")
@CrossOrigin(origins = "http://localhost:3000")
@RequiredArgsConstructor
@Tag(name = "Schedule API", description = "사용자 일정 관리 API (App/Robot 분리)")
@SecurityRequirement(name = "jwtToken") // 클래스 내 모든 API에 자물쇠 아이콘 표시
public class ScheduleController {

    private final ScheduleService scheduleService;

    @Operation(summary = "[App] 일정 등록", description = "보호자가 사용자 일정을 등록합니다.")
    @PostMapping("/app")
    public ScheduleResponseDto createApp(
            @AuthenticationPrincipal User user,
            @Valid @RequestBody ScheduleRequestDto requestDto) {
        return scheduleService.addSchedule(requestDto, user);
    }

    @Operation(summary = "[App] 일정 전체 조회", description = "보호자가 사용자 전체 일정을 조회합니다.")
    @GetMapping("/app")
    public List<ScheduleResponseDto> listAppAll(
            @AuthenticationPrincipal User user,
            @RequestParam String petId) {
        return scheduleService.findAllSchedules(petId, user);
    }

    @Operation(summary = "[App] 일정 월별 조회", description = "보호자가 사용자 특정 월(YYYY-MM) 일정을 조회합니다.")
    @GetMapping("/app/month")
    public List<ScheduleResponseDto> listAppMonth(
            @AuthenticationPrincipal User user,
            @RequestParam String petId,
            @RequestParam String yearMonth) {
        return scheduleService.findSchedulesByMonth(petId, yearMonth, user);
    }

    @Operation(summary = "[App] 일정 일별 조회", description = "보호자가 사용자 특정 날짜(YYYY-MM-DD) 일정을 조회합니다.")
    @GetMapping("/app/day")
    public List<ScheduleResponseDto> listAppDay(
            @AuthenticationPrincipal User user,
            @RequestParam String petId,
            @RequestParam LocalDate date) {
        return scheduleService.findSchedulesByDate(petId, date, user);
    }

    @Operation(summary = "[App] 일정 수정", description = "보호자가 사용자 일정을 수정합니다.")
    @PutMapping("/app/{id}")
    public ScheduleResponseDto updateApp(
            @AuthenticationPrincipal User user,
            @PathVariable Long id,
            @Valid @RequestBody ScheduleRequestDto requestDto) {
        return scheduleService.updateSchedule(id, requestDto, user);
    }

    @Operation(summary = "[App] 일정 삭제", description = "보호자가 사용자 일정을 삭제합니다.")
    @DeleteMapping("/app/{id}")
    public void deleteApp(
            @AuthenticationPrincipal User user,
            @PathVariable Long id,
            @RequestBody ScheduleDeleteRequestDto requestDto) {
        scheduleService.deleteSchedule(id, requestDto.getPetId(), user);
    }

    @Operation(summary = "[Display] 일정 등록", description = "디스플레이에서 직접 일정을 등록합니다.")
    @PostMapping("/pets")
    public ScheduleResponseDto createPet(
            @AuthenticationPrincipal String petId,
            @Valid @RequestBody ScheduleRequestDto requestDto) {
        return scheduleService.addScheduleForPet(requestDto, petId);
    }

    @Operation(summary = "[Display] 내 일정 전체 조회", description = "디스플레이에서 사용자 전체 일정을 조회합니다.")
    @GetMapping("/pets")
    public List<ScheduleResponseDto> listPetAll(
            @AuthenticationPrincipal String petId) {
        return scheduleService.findAllSchedulesByPetId(petId);
    }

    @Operation(summary = "[Display] 내 일정 월별 조회", description = "디스플레이에서 사용자 특정 월(YYYY-MM) 일정을 조회합니다.")
    @GetMapping("/pets/month")
    public List<ScheduleResponseDto> listPetMonth(
            @AuthenticationPrincipal String petId,
            @RequestParam String yearMonth) {
        return scheduleService.findSchedulesByMonthForPet(petId, yearMonth);
    }

    @Operation(summary = "[Display] 내 일정 일별 조회", description = "디스플레이에서 사용자 특정 날짜(YYYY-MM-DD) 일정을 조회합니다.")
    @GetMapping("/pets/day")
    public List<ScheduleResponseDto> listPetDay(
            @AuthenticationPrincipal String petId,
            @RequestParam LocalDate date) {
        return scheduleService.findSchedulesByDateForPet(petId, date);
    }

    @Operation(summary = "[Display] 일정 수정", description = "디스플레이에서 사용자 일정을 수정합니다.")
    @PutMapping("/pets/{id}")
    public ScheduleResponseDto updatePet(
            @AuthenticationPrincipal String petId,
            @PathVariable Long id,
            @Valid @RequestBody ScheduleRequestDto requestDto) {
        return scheduleService.updateScheduleForPet(id, requestDto, petId);
    }

    @Operation(summary = "[Display] 일정 삭제", description = "디스플레이에서 사용자 일정을 삭제합니다.")
    @DeleteMapping("/pets/{id}")
    public void deletePet(
            @AuthenticationPrincipal String petId,
            @PathVariable Long id) {
        scheduleService.deleteScheduleForPet(id, petId);
    }
}
