package com.noill.domain.schedule.service;

import com.noill.domain.user.entity.User;
import com.noill.domain.schedule.dto.ScheduleAnalysisResponseDto;
import com.noill.domain.schedule.dto.ScheduleRequestDto;
import com.noill.domain.schedule.dto.ScheduleResponseDto;
import com.noill.domain.schedule.entity.Schedule;
import com.noill.domain.schedule.repository.ScheduleRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;

@Service
@Transactional
@RequiredArgsConstructor
public class ScheduleService {

    private final ScheduleRepository scheduleRepository;
    private final LlmService llmService; // 1번의 LLM 연동 기능 추가

    // 1. 일정 등록 (기본 CRUD)
    public ScheduleResponseDto addSchedule(ScheduleRequestDto requestDto, User user) {
        if (requestDto.getSchName().contains("금지어")) {
            throw new IllegalArgumentException("적절하지 않은 일정 이름입니다.");
        }

        Schedule savedSchedule = scheduleRepository.save(requestDto.toEntity(user));
        return new ScheduleResponseDto(savedSchedule);
    }

    // 2. 전체 일정 조회
    @Transactional(readOnly = true)
    public List<ScheduleResponseDto> findAllSchedules() {
        return scheduleRepository.findAll().stream()
                .map(ScheduleResponseDto::new)
                .toList();
    }

    // 3. 특정 날짜 일정 조회
    @Transactional(readOnly = true)
    public List<ScheduleResponseDto> findSchedulesByDate(LocalDate date) {
        LocalDateTime startOfDay = date.atStartOfDay();
        LocalDateTime endOfDay = date.atTime(LocalTime.MAX);

        return scheduleRepository.findAllBySchTimeBetween(startOfDay, endOfDay).stream()
                .map(ScheduleResponseDto::new)
                .toList();
    }

    // 4. 일정 수정 (Dirty Checking 활용)
    public ScheduleResponseDto updateSchedule(Long id, ScheduleRequestDto requestDto) {
        Schedule schedule = scheduleRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("해당 일정이 없습니다. id=" + id));

        schedule.update(requestDto.getSchName(), requestDto.getSchMemo(), requestDto.getSchTime());
        return new ScheduleResponseDto(schedule);
    }

    // 5. 일정 삭제
    public void deleteSchedule(Long id) {
        Schedule schedule = scheduleRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("해당 일정이 없습니다. id=" + id));
        scheduleRepository.delete(schedule);
    }

    // ================== 1번 코드에서 추가된 LLM 연동 기능 ==================

    /**
     * 사용자 음성/텍스트 명령 처리 (AIoT 연동 핵심)
     */
    public String processUserCommand(String userText, User user) {
        if (userText == null || userText.trim().isEmpty()) {
            return "죄송해요, 잘 못 들었어요. 다시 한 번 말씀해주세요.";
        }

        try {
            // 1. LLM 분석 서비스 호출
            ScheduleAnalysisResponseDto analysis = llmService.analyzeUserCommand(userText);

            // 2. 명령어 타입이 일정 등록인 경우 처리
            if (analysis.getCmd() != null && "add_schedule".equalsIgnoreCase(analysis.getCmd().getCmdType())) {
                return registerScheduleFromCommand(analysis.getCmd(), user, analysis.getMessage());
            }

            // 3. 그 외 답변 (단순 대화 등) 반환
            return (analysis.getMessage() != null) ? analysis.getMessage() : "네, 알겠어요.";

        } catch (Exception e) {
            e.printStackTrace();
            return "잠시 문제가 생겼어요. 조금 뒤에 다시 말씀해주세요.";
        }
    }

    /**
     * LLM 분석 결과(Command)를 바탕으로 실제 DB 저장
     */
    private String registerScheduleFromCommand(ScheduleAnalysisResponseDto.Command cmd, User user,
            String responseMessage) {
        try {
            if (cmd.getTitle() == null || cmd.getDatetime() == null) {
                return "일정 정보를 정확히 이해하지 못했어요. 다시 말씀해주세요.";
            }

            // ISO-8601 형식(yyyy-MM-ddTHH:mm:ss) 문자열을 LocalDateTime으로 변환
            LocalDateTime schTime = LocalDateTime.parse(cmd.getDatetime());

            Schedule schedule = new Schedule();
            schedule.setUser(user);
            schedule.setSchName(cmd.getTitle());
            schedule.setSchTime(schTime);
            schedule.setSchMemo(cmd.getMemo());
            schedule.setSchStatus("Y");

            scheduleRepository.save(schedule);

            return (responseMessage != null) ? responseMessage : "일정을 등록했어요.";

        } catch (Exception e) {
            return "일정 날짜 형식이 올바르지 않아요.";
        }
    }
}
