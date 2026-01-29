package com.noill.domain.conversation;

import com.noill.domain.care.entity.Care;
import com.noill.domain.care.repository.CareRepository;
import com.noill.domain.conversation.entity.Message;
import com.noill.domain.conversation.entity.Talk;
import com.noill.domain.conversation.repository.MessageRepository;
import com.noill.domain.conversation.repository.TalkRepository;
import com.noill.domain.conversation.service.ConversationBatchService;
import com.noill.domain.conversation.service.LlmService;
import com.noill.domain.pet.entity.Pet;
import com.noill.domain.pet.repository.PetRepository;
import com.noill.domain.user.entity.User;
import com.noill.domain.user.repository.UserRepository;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentMatchers;
import org.mockito.BDDMockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.TestPropertySource;

import java.time.LocalDateTime;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
@TestPropertySource(properties = {
        "spring.datasource.url=jdbc:h2:mem:testdb;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE",
        "spring.datasource.driver-class-name=org.h2.Driver",
        "spring.datasource.username=sa",
        "spring.datasource.password=",
        "spring.jpa.hibernate.ddl-auto=create-drop"
})
public class ConversationBatchTest {

    @Autowired
    private ConversationBatchService batchService;

    @Autowired
    private TalkRepository talkRepository;

    @Autowired
    private MessageRepository messageRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PetRepository petRepository;

    @Autowired
    private CareRepository careRepository;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @MockBean
    private LlmService llmService;

    @AfterEach
    public void tearDown() {
        messageRepository.deleteAll();
        talkRepository.deleteAll();
        careRepository.deleteAll();
        petRepository.deleteAll();
        userRepository.deleteAll();
    }

    @Test
    @DisplayName("배치 통합 테스트: 만료된 세션이 LLM(Mock) 요약을 통해 자동으로 종료되는지 검증")
    public void testBatchClosesExpiredSessionsWithMockLLM() {
        // Given
        User user = userRepository.save(User.builder()
                .userId("test@test.com")
                .userPassword("pw")
                .userName("TestUser")
                .userAddress("Seoul")
                .userPhone("010-1234-5678")
                .build());

        Pet pet = petRepository.save(Pet.builder()
                .petId("pet123")
                .petName("Bbibbo")
                .petAddress("Seoul")
                .petPhone("010-1111-2222")
                .petBirth(LocalDateTime.now())
                .build());

        // Care 연결 생성 (정합성)
        careRepository.save(Care.builder()
                .user(user)
                .pet(pet)
                .careName("Family")
                .build());

        // 1. 만료된 세션 (4시간 전 마지막 메시지) -> 종료 대상
        Talk expiredTalk = talkRepository.save(Talk.builder()
                .pet(pet)
                .talkName("Old Session")
                .status("Y")
                .build());
        createMessage(expiredTalk, "안녕 삐뽀야", 4);
        createMessage(expiredTalk, "산책 가자", 4);

        // 2. 최신 세션 (1시간 전 마지막 메시지) -> 유지 대상
        Talk activeTalk = talkRepository.save(Talk.builder()
                .pet(pet)
                .talkName("Active Session")
                .status("Y")
                .build());
        createMessage(activeTalk, "지금은 뭐해?", 1);

        // API Mocking 설정: generateSessionTitle(String) 호출 시 "Mocked Title" 반환
        BDDMockito.given(llmService.generateSessionTitle(ArgumentMatchers.anyString()))
                .willReturn("Mocked Title");

        // WHEN: 배치 실행
        System.out.println(">>> [Test] 배치 실행 시작 (Mocked LLM)");
        batchService.closeExpiredSessions();
        System.out.println(">>> [Test] 배치 실행 종료");

        // THEN
        // 1. 만료된 세션 검증
        Talk updatedExpiredTalk = talkRepository.findById(expiredTalk.getTalkNo()).orElseThrow();
        assertThat(updatedExpiredTalk.getStatus()).isEqualTo("N");
        System.out.println(">>> 요약된 제목: " + updatedExpiredTalk.getTalkName());

        // Mocking된 제목으로 바뀌었는지 확인
        assertThat(updatedExpiredTalk.getTalkName()).isEqualTo("Mocked Title");

        // 2. 최신 세션 검증
        Talk updatedActiveTalk = talkRepository.findById(activeTalk.getTalkNo()).orElseThrow();
        assertThat(updatedActiveTalk.getStatus()).isEqualTo("Y");
        assertThat(updatedActiveTalk.getTalkName()).isEqualTo("Active Session");
    }

    private void createMessage(Talk talk, String content, int hoursAgo) {
        Message message = Message.builder()
                .talk(talk)
                .msgType("Q")
                .msgContent(content)
                .build();

        messageRepository.save(message);

        // 강제 시간 조작 (JdbcTemplate 사용)
        LocalDateTime pastTime = LocalDateTime.now().minusHours(hoursAgo);
        jdbcTemplate.update("UPDATE messages SET created_at = ? WHERE msg_no = ?", pastTime, message.getMsgNo());
    }
}
