package com.noill.domain.schedule;

import com.noill.domain.pet.entity.Pet;
import com.noill.domain.schedule.dto.ScheduleAnalysisResponseDto;
import com.noill.domain.schedule.repository.ScheduleRepository;
import com.noill.domain.schedule.service.LlmService;
import com.noill.domain.schedule.service.ScheduleService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;

@ExtendWith(MockitoExtension.class)
class LlmScheduleServiceTest {

    @Mock
    private LlmService llmService;

    @Mock
    private ScheduleRepository scheduleRepository;

    @InjectMocks
    private ScheduleService scheduleService;

    @Test
    @DisplayName("필수 정보(시간)가 누락되면 DB에 저장하지 않고 되묻는 메시지를 반환한다")
    void shouldAskForTime_WhenTimeIsMissing() {
        // Given
        Pet pet = Pet.builder().petId("testPet").petName("멍멍이").build();
        String userText = "나 친구랑 약속 잡아줘";
        System.out.println("\n[Test 1] 시간 정보 누락 케이스");
        System.out.println("User Input: " + userText);

        // LLM이 제목은 찾았지만 시간(datetime)은 null로 반환하는 상황 Mocking
        ScheduleAnalysisResponseDto mockResponse = new ScheduleAnalysisResponseDto();
        ScheduleAnalysisResponseDto.Command command = new ScheduleAnalysisResponseDto.Command();
        command.setCmdType("add_schedule");
        command.setTitle("친구랑 약속");
        command.setDatetime(null); // 시간 누락!

        mockResponse.setCmd(command);
        mockResponse.setMessage("언제 약속을 잡을까요?"); // LLM이 생성했을 되묻기 메시지
        System.out.println("Mock LLM Response: datetime=null, message=" + mockResponse.getMessage());

        given(llmService.analyzeUserCommand(userText)).willReturn(mockResponse);

        // When
        String resultMessage = scheduleService.processUserCommand(userText, pet);
        System.out.println("Service Result: " + resultMessage);

        // Then
        assertThat(resultMessage).isEqualTo("일정 정보를 정확히 이해하지 못했어요. 다시 말씀해주세요."); // Service에서 null 체크 후 반환하는 메시지 확인

        // 중요: save 메서드가 *절대* 호출되지 않았어야 함
        verify(scheduleRepository, never()).save(any());
    }

    @Test
    @DisplayName("필수 정보(제목)가 누락되면 DB에 저장하지 않고 되묻는 메시지를 반환한다")
    void shouldAskForTitle_WhenTitleIsMissing() {
        // Given
        Pet pet = Pet.builder().petId("testPet").petName("멍멍이").build();
        String userText = "내일 오후 2시에 일정 잡아줘";
        System.out.println("\n[Test 2] 제목 정보 누락 케이스");
        System.out.println("User Input: " + userText);

        // LLM이 시간은 찾았지만 제목(title)은 null로 반환하는 상황 Mocking
        ScheduleAnalysisResponseDto mockResponse = new ScheduleAnalysisResponseDto();
        ScheduleAnalysisResponseDto.Command command = new ScheduleAnalysisResponseDto.Command();
        command.setCmdType("add_schedule");
        command.setTitle(null); // 제목 누락!
        command.setDatetime("2026-01-24T14:00:00");

        mockResponse.setCmd(command);
        mockResponse.setMessage("어떤 일정을 잡을까요?");
        System.out.println("Mock LLM Response: title=null, message=" + mockResponse.getMessage());

        given(llmService.analyzeUserCommand(userText)).willReturn(mockResponse);

        // When
        String resultMessage = scheduleService.processUserCommand(userText, pet);
        System.out.println("Service Result: " + resultMessage);

        // Then
        assertThat(resultMessage).isEqualTo("일정 정보를 정확히 이해하지 못했어요. 다시 말씀해주세요.");

        // 중요: save 메서드가 호출되지 않았어야 함
        verify(scheduleRepository, never()).save(any());
    }
}
