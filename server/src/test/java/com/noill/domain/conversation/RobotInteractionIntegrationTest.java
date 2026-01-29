package com.noill.domain.conversation;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.noill.domain.care.entity.Care;
import com.noill.domain.care.repository.CareRepository;
import com.noill.domain.conversation.dto.LlmAnalysisResult;
import com.noill.domain.conversation.dto.LlmIntent;
import com.noill.domain.conversation.dto.TalkRequestDto;
import com.noill.domain.conversation.service.LlmService;
import com.noill.domain.pet.entity.Pet;
import com.noill.domain.pet.repository.PetRepository;
import com.noill.domain.schedule.repository.ScheduleRepository;
import com.noill.domain.user.entity.User;
import com.noill.domain.user.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.BDDMockito.given;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultHandlers.print;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@Transactional
@ActiveProfiles("test")
public class RobotInteractionIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private PetRepository petRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private CareRepository careRepository;

    @Autowired
    private ScheduleRepository scheduleRepository;

    @MockitoBean
    private LlmService llmService;

    private Pet testPet;
    private User testUser;

    @BeforeEach
    void setUp() {
        // 1. 유저 생성
        testUser = userRepository.save(User.builder()
                .userId("testuser1")
                .userPassword("password")
                .userName("김철수")
                .userAddress("서울시 강남구")
                .userPhone("010-1234-5678")
                .build());

        // 2. 펫 생성 (Pet 엔티티 생성자 필드 반영)
        testPet = petRepository.save(Pet.builder()
                .petId("robot-001")
                .petName("노일이")
                .petAddress("서울시 강남구")
                .petPhone("010-9876-5432")
                .petOwner("김철수")
                .petBirth(LocalDateTime.now())
                .build());

        // 3. 케어(Care) 관계 생성 (User <-> Pet 연결)
        careRepository.save(Care.builder()
                .user(testUser)
                .pet(testPet)
                .careName("우리집 막내")
                .build());
    }

    @Test
    @DisplayName("일정 등록 요청 시 - ScheduleService가 호출되고 DB에 저장된다")
    @WithMockUser
    void whenScheduleRequest_thenSaveSchedule() throws Exception {
        // Given
        String userText = "내일 2시에 병원 가야해";
        LocalDateTime schTime = LocalDateTime.now().plusDays(1).withHour(14).withMinute(0);

        LlmAnalysisResult mockResult = LlmAnalysisResult.builder()
                .intent(LlmIntent.SCHEDULE)
                .content("네, 내일 2시 병원 일정을 등록했어요.")
                .scheduleData(LlmAnalysisResult.ScheduleData.builder()
                        .schName("병원 방문")
                        .schTime(schTime)
                        .schMemo("병원 진료")
                        .build())
                .build();

        given(llmService.analyzeUserCommand(anyString())).willReturn(mockResult);

        TalkRequestDto request = new TalkRequestDto(testPet.getPetNo(), userText);

        // When & Then
        mockMvc.perform(post("/api/conversations/talk")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andDo(print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.reply").value("네, 내일 2시 병원 일정을 등록했어요."))
                .andExpect(jsonPath("$.action").value("SCHEDULE_ADDED"));

        // DB 검증
        assertThat(scheduleRepository.findAllByPetPetNo(testPet.getPetNo())).hasSize(1);
    }

    @Test
    @DisplayName("일상 대화 요청 시 - DB 저장 없이 대화 응답만 반환한다")
    @WithMockUser
    void whenDailyTalkRequest_thenJustReply() throws Exception {
        // Given
        String userText = "안녕 바둑아";
        LlmAnalysisResult mockResult = LlmAnalysisResult.builder()
                .intent(LlmIntent.DAILY_TALK)
                .content("멍멍! 안녕하세요 어르신!")
                .build();

        given(llmService.analyzeUserCommand(anyString())).willReturn(mockResult);

        TalkRequestDto request = new TalkRequestDto(testPet.getPetNo(), userText);

        // When & Then
        mockMvc.perform(post("/api/conversations/talk")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andDo(print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.reply").value("멍멍! 안녕하세요 어르신!"))
                .andExpect(jsonPath("$.action").value("NONE"));

        // DB 검증
        assertThat(scheduleRepository.findAllByPetPetNo(testPet.getPetNo())).isEmpty();
    }

    @Test
    @DisplayName("일상 대화 요청 시 - 세션(Talk)과 메시지(Message)가 저장된다")
    @WithMockUser
    void whenDailyTalkRequest_thenCreateTalkAndMessages() throws Exception {
        // Given
        String userText = "오늘 날씨 어때?";
        LlmAnalysisResult mockResult = LlmAnalysisResult.builder()
                .intent(LlmIntent.DAILY_TALK)
                .content("오늘은 맑아요!")
                .build();

        given(llmService.analyzeUserCommand(anyString())).willReturn(mockResult);

        TalkRequestDto request = new TalkRequestDto(testPet.getPetNo(), userText);

        // When
        mockMvc.perform(post("/api/conversations/talk")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andDo(print())
                .andExpect(status().isOk());

        // Then (DB 검증)
        // 1. Talk(세션) 생성 확인
        assertThat(conversationService.getValidTalk(testPet)).isNotNull();
        
        // 2. 메시지 저장 확인 (Q, A 각각 1개씩 총 2개)
        Talk talk = conversationService.getValidTalk(testPet);
        assertThat(messageRepository.countByTalk_TalkNo(talk.getTalkNo())).isEqualTo(2);
    }
    
    // Test에 필요한 리포지토리/서비스 주입
    @Autowired
    private com.noill.domain.conversation.service.ConversationService conversationService;
    
    @Autowired
    private com.noill.domain.conversation.repository.MessageRepository messageRepository;
}
