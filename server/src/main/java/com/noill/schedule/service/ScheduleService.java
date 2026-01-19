package com.noill.schedule.service;

import com.noill.schedule.entity.Schedule;
import com.noill.schedule.dto.ScheduleRequestDto;
import com.noill.schedule.dto.ScheduleResponseDto;
import com.noill.schedule.repository.ScheduleRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;

/**
 * ScheduleService
 * 수정(Update)과 삭제(Delete) 비즈니스 로직이 추가되었습니다.
 */
@Service
@Transactional
@RequiredArgsConstructor
public class ScheduleService {

    private final ScheduleRepository scheduleRepository;

    // 일정 등록
    public ScheduleResponseDto addSchedule(ScheduleRequestDto requestDto) {
        if (requestDto.getSchName().contains("금지어")) {
            throw new IllegalArgumentException("적절하지 않은 일정 이름입니다.");
        }
        Schedule savedSchedule = scheduleRepository.save(requestDto.toEntity());
        return new ScheduleResponseDto(savedSchedule);
    }

    // 전체 일정 조회 (자동으로 삭제된 건 제외됨)
    @Transactional(readOnly = true)
    public List<ScheduleResponseDto> findAllSchedules() {
        return scheduleRepository.findAll().stream()
                .map(ScheduleResponseDto::new)
                .toList();
    }

    // 특정 날짜의 일정 조회 (자동으로 삭제된 건 제외됨)
    @Transactional(readOnly = true)
    public List<ScheduleResponseDto> findSchedulesByDate(LocalDate date) {
        LocalDateTime startOfDay = date.atStartOfDay();
        LocalDateTime endOfDay = date.atTime(LocalTime.MAX);

        return scheduleRepository.findAllBySchTimeBetween(startOfDay, endOfDay).stream()
                .map(ScheduleResponseDto::new)
                .toList();
    }

    /**
     * 일정 수정 (JPA 변경 감지 활용)
     * 트랜잭션 내에서 조회한 Entity의 값을 변경하면, 트랜잭션 종료 시 Update 쿼리가 자동 실행됩니다.
     */
    public ScheduleResponseDto updateSchedule(Long id, ScheduleRequestDto requestDto) {
        Schedule schedule = scheduleRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("해당 일정이 없습니다. id=" + id));

        // Entity의 편의 메서드를 사용하여 값 변경 (Dirty Checking)
        schedule.update(requestDto.getSchName(), requestDto.getSchMemo(), requestDto.getSchTime());

        return new ScheduleResponseDto(schedule);
    }

    /**
     * 일정 삭제 (논리적 삭제)
     * 실제 DB에서 지우지 않고, 상태값만 변경합니다.
     */
    public void deleteSchedule(Long id) {
        Schedule schedule = scheduleRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("해당 일정이 없습니다. id=" + id));

        // 상태를 'N'으로 변경
        schedule.deleteLogic();
    }
}
