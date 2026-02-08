package com.noill.domain.schedule.service;

import com.noill.domain.conversation.dto.LlmAnalysisResult;
import com.noill.domain.conversation.dto.LlmIntent;
import com.noill.domain.conversation.service.LlmService;
import com.noill.domain.pet.entity.Pet;
import com.noill.domain.pet.repository.PetRepository;
import com.noill.domain.care.repository.CareRepository;
import com.noill.domain.user.entity.User;
import com.noill.domain.schedule.dto.ScheduleRequestDto;
import com.noill.domain.schedule.dto.ScheduleResponseDto;
import com.noill.domain.schedule.entity.Schedule;
import com.noill.domain.schedule.repository.ScheduleRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.YearMonth;
import java.util.List;

@Service
@Transactional
@RequiredArgsConstructor
public class ScheduleService {

    private final ScheduleRepository scheduleRepository;
    private final LlmService llmService;
    private final CareRepository careRepository;
    private final PetRepository petRepository;

    // 1. 일정 등록
    public ScheduleResponseDto addSchedule(ScheduleRequestDto requestDto, User user) {
        Pet pet = resolveAndValidatePet(requestDto.getPetId(), user);

        Schedule savedSchedule = scheduleRepository.save(requestDto.toEntity(pet));
        return new ScheduleResponseDto(savedSchedule);
    }

    // 2. 전체 일정 조회 (특정 노인 기준)
    @Transactional(readOnly = true)
    public List<ScheduleResponseDto> findAllSchedules(String petId, User user) {
        Pet pet = resolveAndValidatePet(petId, user);

        return scheduleRepository.findAllByPetPetNo(pet.getPetNo()).stream()
                .map(ScheduleResponseDto::new)
                .toList();
    }

    // 3. 특정 날짜 일정 조회
    @Transactional(readOnly = true)
    public List<ScheduleResponseDto> findSchedulesByDate(String petId, LocalDate date, User user) {
        Pet pet = resolveAndValidatePet(petId, user);

        LocalDateTime startOfDay = date.atStartOfDay();
        LocalDateTime endOfDay = date.atTime(LocalTime.MAX);

        return scheduleRepository.findAllByPetPetNoAndSchTimeBetween(pet.getPetNo(), startOfDay, endOfDay).stream()
                .map(ScheduleResponseDto::new)
                .toList();
    }

    // 4. 특정 월(Month) 일정 조회
    @Transactional(readOnly = true)
    public List<ScheduleResponseDto> findSchedulesByMonth(String petId, String yearMonth, User user) {
        Pet pet = resolveAndValidatePet(petId, user);

        // yyyy-MM 형식 파싱
        YearMonth ym = YearMonth.parse(yearMonth);
        LocalDateTime startOfMonth = ym.atDay(1).atStartOfDay();
        LocalDateTime endOfMonth = ym.atEndOfMonth().atTime(LocalTime.MAX);

        return scheduleRepository.findAllByPetPetNoAndSchTimeBetween(pet.getPetNo(), startOfMonth, endOfMonth).stream()
                .map(ScheduleResponseDto::new)
                .toList();
    }

    // 4. 일정 수정
    public ScheduleResponseDto updateSchedule(Long schNo, ScheduleRequestDto requestDto, User user) {
        Schedule schedule = scheduleRepository.findById(schNo)
                .orElseThrow(() -> new IllegalArgumentException("해당 일정이 없습니다. id=" + schNo));

        Pet requestPet = resolveAndValidatePet(requestDto.getPetId(), user);

        if (!schedule.getPet().getPetNo().equals(requestPet.getPetNo())) {
            throw new IllegalArgumentException("요청한 사용자 정보가 일치하지 않습니다.");
        }

        schedule.update(requestDto.getSchName(), requestDto.getSchMemo(), requestDto.getSchTime());
        return new ScheduleResponseDto(schedule);
    }

    // 5. 일정 삭제
    public void deleteSchedule(Long schNo, String petId, User user) {
        Schedule schedule = scheduleRepository.findById(schNo)
                .orElseThrow(() -> new IllegalArgumentException("해당 일정이 없습니다. id=" + schNo));

        // 권한 및 일치 확인
        Pet requestPet = resolveAndValidatePet(petId, user);

        if (!schedule.getPet().getPetNo().equals(requestPet.getPetNo())) {
            throw new IllegalArgumentException("요청한 사용자 정보가 일치하지 않습니다.");
        }

        scheduleRepository.delete(schedule);
    }

    // ================= [로봇(Pet)용 메서드] =================

    // 1. 본인 일정 조회 (로봇용)
    @Transactional(readOnly = true)
    public List<ScheduleResponseDto> findAllSchedulesByPetId(String petId) {
        Pet pet = findPetByPetIdOrThrow(petId);

        return scheduleRepository.findAllByPetPetNo(pet.getPetNo()).stream()
                .map(ScheduleResponseDto::new)
                .toList();
    }

    // 2. 특정 월(Month) 일정 조회 (로봇용)
    @Transactional(readOnly = true)
    public List<ScheduleResponseDto> findSchedulesByMonthForPet(String petId, String yearMonth) {
        Pet pet = findPetByPetIdOrThrow(petId);

        YearMonth ym = YearMonth.parse(yearMonth);
        LocalDateTime startOfMonth = ym.atDay(1).atStartOfDay();
        LocalDateTime endOfMonth = ym.atEndOfMonth().atTime(LocalTime.MAX);

        return scheduleRepository.findAllByPetPetNoAndSchTimeBetween(pet.getPetNo(), startOfMonth, endOfMonth).stream()
                .map(ScheduleResponseDto::new)
                .toList();
    }

    // 3. 특정 날짜 일정 조회 (로봇용)
    @Transactional(readOnly = true)
    public List<ScheduleResponseDto> findSchedulesByDateForPet(String petId, LocalDate date) {
        Pet pet = findPetByPetIdOrThrow(petId);

        LocalDateTime startOfDay = date.atStartOfDay();
        LocalDateTime endOfDay = date.atTime(LocalTime.MAX);

        return scheduleRepository.findAllByPetPetNoAndSchTimeBetween(pet.getPetNo(), startOfDay, endOfDay).stream()
                .map(ScheduleResponseDto::new)
                .toList();
    }

    // 4. 일정 등록 (로봇용)
    public ScheduleResponseDto addScheduleForPet(ScheduleRequestDto requestDto, String petId) {
        Pet pet = findPetByPetIdOrThrow(petId);
        Schedule savedSchedule = scheduleRepository.save(requestDto.toEntity(pet));
        return new ScheduleResponseDto(savedSchedule);
    }

    // 5. 일정 수정 (로봇용)
    public ScheduleResponseDto updateScheduleForPet(Long schNo, ScheduleRequestDto requestDto, String petId) {
        Schedule schedule = scheduleRepository.findById(schNo)
                .orElseThrow(() -> new IllegalArgumentException("해당 일정이 없습니다. id=" + schNo));

        Pet pet = findPetByPetIdOrThrow(petId);

        // 내 일정인지 확인
        if (!schedule.getPet().getPetNo().equals(pet.getPetNo())) {
            throw new AccessDeniedException("본인의 일정만 수정할 수 있습니다.");
        }

        schedule.update(requestDto.getSchName(), requestDto.getSchMemo(), requestDto.getSchTime());
        return new ScheduleResponseDto(schedule);
    }

    // 6. 일정 삭제 (로봇용)
    public void deleteScheduleForPet(Long schNo, String petId) {
        Schedule schedule = scheduleRepository.findById(schNo)
                .orElseThrow(() -> new IllegalArgumentException("해당 일정이 없습니다. id=" + schNo));

        Pet pet = findPetByPetIdOrThrow(petId);

        // 내 일정인지 확인
        if (!schedule.getPet().getPetNo().equals(pet.getPetNo())) {
            throw new AccessDeniedException("본인의 일정만 삭제할 수 있습니다.");
        }

        scheduleRepository.delete(schedule);
    }

    private Pet findPetByPetIdOrThrow(String petId) {
        return petRepository.findByPetId(petId)
                .orElseThrow(() -> new IllegalArgumentException("해당 로봇을 찾을 수 없습니다: " + petId));
    }

    private Pet resolveAndValidatePet(String petId, User user) {
        // 1. 로봇 식별 (petId(로봇 일련번호) 필수)
        if (petId == null || petId.isBlank()) {
            throw new IllegalArgumentException("로봇 식별 정보(petId)가 필요합니다.");
        }

        Pet pet = petRepository.findByPetId(petId)
                .orElseThrow(() -> new IllegalArgumentException("해당 로봇 일련번호를 가진 사용자를 찾을 수 없습니다: " + petId));

        // 2. 권한 검증
        // User 정보가 있으면(앱 요청), 해당 유저가 이 어르신의 보호자인지 검증 (Security)
        // User 정보가 없으면(디스플레이 요청), 로봇 식별만으로 통과
        if (user != null) {
            if (!careRepository.existsByUserAndPet(user, pet)) {
                throw new AccessDeniedException("해당 사용자 대한 접근 권한이 없습니다.");
            }
        }

        return pet;
    }

    // ================== LLM 연동 기능 ==================

    /**
     * 사용자 음성/텍스트 명령 처리 (AIoT 연동 핵심)
     */
    public String processUserCommand(String userText, Pet pet) {
        if (userText == null || userText.trim().isEmpty()) {
            return "죄송해요, 잘 못 들었어요. 다시 한 번 말씀해주세요.";
        }

        try {
            // 1. LLM 분석 서비스 호출
            LlmAnalysisResult analysis = llmService.analyzeUserCommand(userText);

            if (analysis.getIntent() == LlmIntent.SCHEDULE && analysis.getScheduleData() != null) {
                return addScheduleFromLlm(analysis.getScheduleData(), pet, analysis.getContent());
            }

            // 3. 그 외 답변 (단순 대화 등) 반환
            return (analysis.getContent() != null) ? analysis.getContent() : "네, 알겠어요.";

        } catch (Exception e) {
            e.printStackTrace();
            return "잠시 문제가 생겼어요. 조금 뒤에 다시 말씀해주세요.";
        }
    }

    /**
     * LLM 분석 결과(Command)를 바탕으로 실제 DB 저장 (Dispatcher 호출용)
     */
    public String addScheduleFromLlm(LlmAnalysisResult.ScheduleData scheduleData, Pet pet,
                                     String responseMessage) {
        try {
            if (scheduleData.getSchName() == null || scheduleData.getSchTime() == null) {
                return "일정 정보를 정확히 이해하지 못했어요. 다시 말씀해주세요.";
            }

            Schedule schedule = new Schedule();
            schedule.setPet(pet);
            schedule.setSchName(scheduleData.getSchName());
            schedule.setSchTime(scheduleData.getSchTime());
            schedule.setSchMemo(scheduleData.getSchMemo());
            schedule.setSchStatus("Y");

            scheduleRepository.save(schedule);

            return (responseMessage != null) ? responseMessage : "일정을 등록했어요.";

        } catch (Exception e) {
            return "일정 처리에 실패했어요.";
        }
    }
}
