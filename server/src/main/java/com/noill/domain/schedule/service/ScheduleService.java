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
import java.util.List;

@Service
@Transactional
@RequiredArgsConstructor
public class ScheduleService {

    private final ScheduleRepository scheduleRepository;
    private final LlmService llmService;
    private final CareRepository careRepository;
    private final PetRepository petRepository;

    // 1. 일정 등록 (권한 검증 포함)
    public ScheduleResponseDto addSchedule(ScheduleRequestDto requestDto, User user) {
        Pet pet = resolveAndValidatePet(requestDto.getPetNo(), requestDto.getPetId(), user);

        Schedule savedSchedule = scheduleRepository.save(requestDto.toEntity(pet));
        return new ScheduleResponseDto(savedSchedule);
    }

    // 2. 전체 일정 조회 (특정 펫 기준)
    @Transactional(readOnly = true)
    public List<ScheduleResponseDto> findAllSchedules(Long petNo, String petId, User user) {
        Pet pet = resolveAndValidatePet(petNo, petId, user);

        return scheduleRepository.findAllByPetPetNo(pet.getPetNo()).stream()
                .map(ScheduleResponseDto::new)
                .toList();
    }

    // 3. 특정 날짜 일정 조회
    @Transactional(readOnly = true)
    public List<ScheduleResponseDto> findSchedulesByDate(Long petNo, String petId, LocalDate date, User user) {
        Pet pet = resolveAndValidatePet(petNo, petId, user);

        LocalDateTime startOfDay = date.atStartOfDay();
        LocalDateTime endOfDay = date.atTime(LocalTime.MAX);

        return scheduleRepository.findAllByPetPetNoAndSchTimeBetween(pet.getPetNo(), startOfDay, endOfDay).stream()
                .map(ScheduleResponseDto::new)
                .toList();
    }

    // 4. 일정 수정 (권한 검증 + 데이터 소유 확인)
    public ScheduleResponseDto updateSchedule(Long schNo, ScheduleRequestDto requestDto, User user) {
        Schedule schedule = scheduleRepository.findById(schNo)
                .orElseThrow(() -> new IllegalArgumentException("해당 일정이 없습니다. id=" + schNo));

        // 요청된 펫(식별자)과 일정의 펫 일치 여부 확인을 위해 resolve 호출
        // 수정 권한이 있는지(내 펫인지) 확인하는 과정이기도 함
        Pet requestPet = resolveAndValidatePet(requestDto.getPetNo(), requestDto.getPetId(), user);

        if (!schedule.getPet().getPetNo().equals(requestPet.getPetNo())) {
            throw new IllegalArgumentException("요청한 펫 정보가 일정의 실제 펫과 일치하지 않습니다.");
        }

        schedule.update(requestDto.getSchName(), requestDto.getSchMemo(), requestDto.getSchTime());
        return new ScheduleResponseDto(schedule);
    }

    // 5. 일정 삭제 (권한 검증)
    public void deleteSchedule(Long schNo, Long petNo, String petId, User user) {
        Schedule schedule = scheduleRepository.findById(schNo)
                .orElseThrow(() -> new IllegalArgumentException("해당 일정이 없습니다. id=" + schNo));

        // 권한 및 일치 확인
        Pet requestPet = resolveAndValidatePet(petNo, petId, user);

        if (!schedule.getPet().getPetNo().equals(requestPet.getPetNo())) {
            throw new IllegalArgumentException("요청한 펫 정보가 일정의 실제 펫과 일치하지 않습니다.");
        }

        scheduleRepository.delete(schedule);
    }

    // 공통 펫 해석 및 권한 검증 메서드
    private Pet resolveAndValidatePet(Long petNo, String petId, User user) {
        Pet pet = null;

        // 1. 펫 식별
        if (petId != null && !petId.isBlank()) {
            pet = petRepository.findByPetId(petId)
                    .orElseThrow(() -> new IllegalArgumentException("해당 petId를 가진 반려동물을 찾을 수 없습니다: " + petId));
        } else if (petNo != null) {
            pet = petRepository.findById(petNo)
                    .orElseThrow(() -> new IllegalArgumentException("해당 petNo를 가진 반려동물을 찾을 수 없습니다: " + petNo));
        } else {
            throw new IllegalArgumentException("펫 식별 정보(petId 또는 petNo)가 필요합니다.");
        }

        // 2. 권한 검증 (App 요청인 경우)
        if (user != null) {
            if (!careRepository.existsByUserAndPet(user, pet)) {
                throw new AccessDeniedException("해당 팻에 대한 접근 권한이 없습니다.");
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

            // 2. 명령어 타입이 일정 등록인 경우 처리
            if (analysis.getIntent() == LlmIntent.SCHEDULE && analysis.getScheduleData() != null) {
                return registerScheduleFromCommand(analysis.getScheduleData(), pet, analysis.getContent());
            }

            // 3. 그 외 답변 (단순 대화 등) 반환
            return (analysis.getContent() != null) ? analysis.getContent() : "네, 알겠어요.";

        } catch (Exception e) {
            e.printStackTrace();
            return "잠시 문제가 생겼어요. 조금 뒤에 다시 말씀해주세요.";
        }
    }

    /**
     * LLM 분석 결과(Command)를 바탕으로 실제 DB 저장
     */
    private String registerScheduleFromCommand(LlmAnalysisResult.ScheduleData scheduleData, Pet pet,
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
