package com.noill.domain.conversation;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.noill.domain.care.entity.Care;
import com.noill.domain.care.repository.CareRepository;
import com.noill.domain.conversation.dto.LlmAnalysisResult;
import com.noill.domain.conversation.dto.LlmIntent;
import com.noill.domain.conversation.dto.TalkRequestDto;
import com.noill.domain.conversation.entity.Talk;
import com.noill.domain.conversation.service.ConversationService;
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
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;

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

    @PersistenceContext
    private EntityManager em;

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

    @Autowired
    private ConversationService conversationService;

    @Autowired
    private com.noill.domain.conversation.repository.MessageRepository messageRepository;

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
    @DisplayName("일상 대화 요청 시 - DB 저장 없이 대화 응답만 반환한다 (스케줄 미저장)")
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

        // 스케줄은 저장되지 않아야 함
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
        Talk talk = conversationService.getValidTalk(testPet);
        assertThat(talk).isNotNull();
        assertThat(messageRepository.countByTalk_TalkNo(talk.getTalkNo())).isEqualTo(2);
    }

    @Test
    @DisplayName("마지막 대화 후 3시간이 지나면 - 새로운 세션(Talk)이 생성된다")
    @Transactional
    void whenThreeHoursPassed_thenCreateNewTalk() {
        // Given
        // 1. 초기 세션 생성
        Talk oldTalk = conversationService.getValidTalk(testPet);
        
        // 2. 메시지 생성 (User Msg)
        conversationService.saveUserMessage(testPet, "3시간 전 대화입니다.");
        
        // 3. 강제로 메시지 시간을 4시간 전으로 변경 (JPA Auditing 우회)
        // native query update
        jakarta.persistence.Query query = em.createNativeQuery(
                "UPDATE MESSAGES SET CREATED_AT = :time WHERE TALK_NO = :talkNo");
        query.setParameter("time", LocalDateTime.now().minusHours(4));
        query.setParameter("talkNo", oldTalk.getTalkNo());
        query.executeUpdate();
        
        em.flush();
        em.clear(); // 영속성 컨텍스트 초기화 (DB에서 다시 조회하도록)

        // When
        // 4. 새로운 대화 요청 (getValidTalk 호출)
        Talk newTalk = conversationService.getValidTalk(testPet);

        // Then
        // 5. 세션이 달라야 함
        assertThat(newTalk.getTalkNo()).isNotEqualTo(oldTalk.getTalkNo());
        assertThat(newTalk.getStatus()).isEqualTo("Y");
        
        // 6. 이전 세션은 닫혔는지 확인 (단, getValidTalk 로직상 닫힘 처리됨)
        // 다시 조회해서 확인
        Talk closedTalk = em.find(Talk.class, oldTalk.getTalkNo());
        assertThat(closedTalk.getStatus()).isEqualTo("N");
    }

    @Test
    @DisplayName("메시지가 50개를 초과하면 - 오래된 메시지 2개가 삭제된다 (Rolling Window)")
    @Transactional
    void whenMessageCountExceedsLimit_thenDeleteOldestMessages() {
        // Given
        Talk talk = conversationService.getValidTalk(testPet);
        
        // 1. 메시지 50개 생성
        for (int i = 1; i <= 50; i++) {
            conversationService.saveBotMessage(talk, "메시지 " + i);
        }
        // count 확인: 50개여야 함
        assertThat(messageRepository.countByTalk_TalkNo(talk.getTalkNo())).isEqualTo(50);

        // When
        // 2. 51번째 메시지 추가 (saveBotMessage 내부에서 Rolling Window 동작)
        // saveBotMessage는 메시지 저장 후 -> count > 50 체크 -> 상위 2개 삭제
        conversationService.saveBotMessage(talk, "51번째 메시지");

        // Then
        // 3. 기대 결과: 50 + 1 - 2 = 49개
        long finalCount = messageRepository.countByTalk_TalkNo(talk.getTalkNo());
        assertThat(finalCount).isEqualTo(49);
    }
}
