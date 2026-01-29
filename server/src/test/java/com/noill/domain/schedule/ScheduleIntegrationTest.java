package com.noill.domain.schedule;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.noill.domain.care.entity.Care;
import com.noill.domain.care.repository.CareRepository;
import com.noill.domain.conversation.service.LlmService;
import com.noill.domain.pet.entity.Pet;
import com.noill.domain.pet.repository.PetRepository;
import com.noill.domain.schedule.dto.ScheduleRequestDto;
import com.noill.domain.schedule.repository.ScheduleRepository;
import com.noill.domain.user.entity.User;
import com.noill.domain.user.repository.UserRepository;
import com.noill.global.security.jwt.JwtTokenProvider;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@Transactional
@ActiveProfiles("test")
public class ScheduleIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PetRepository petRepository;

    @Autowired
    private CareRepository careRepository;

    @Autowired
    private ScheduleRepository scheduleRepository;

    @Autowired
    private JwtTokenProvider jwtTokenProvider;

    @Autowired
    private ObjectMapper objectMapper;

    @MockitoBean
    private LlmService llmService;

    private User userA;
    private User userB;
    private Pet petA;
    private Pet petB;
    private String tokenUserA;

    @BeforeEach
    void setUp() {
        // 1. User 생성
        userA = userRepository.save(User.builder()
                .userId("userA")
                .userPassword("password")
                .userName("User A")
                .userAddress("Seoul")
                .userPhone("010-1111-1111")
                .build());

        userB = userRepository.save(User.builder()
                .userId("userB")
                .userPassword("password")
                .userName("User B")
                .userAddress("Busan")
                .userPhone("010-2222-2222")
                .build());

        // 2. Pet 생성
        petA = petRepository.save(Pet.builder()
                .petId("petA")
                .petName("Pet A")
                .petAddress("Seoul")
                .petPhone("010-3333-3333")
                .build());

        // Pet B는 아무와도 연결하지 않거나, User B와 연결
        petB = petRepository.save(Pet.builder()
                .petId("petB")
                .petName("Pet B")
                .petAddress("Busan")
                .petPhone("010-4444-4444")
                .build());

        // 3. Care 관계 설정 (UserA <-> PetA) 수정
        careRepository.save(Care.builder()
                .user(userA)
                .pet(petA)
                .careName("My Pet A")
                .build());

        // UserB는 PetB와 연결 수정
        careRepository.save(Care.builder()
                .user(userB)
                .pet(petB)
                .careName("My Pet B")
                .build());

        // 4. Token 발급
        tokenUserA = jwtTokenProvider.generateToken(userA.getUserId());
    }

    @Test
    @DisplayName("[App] 정상 등록: 보호자가 본인의 펫 일정 등록")
    void createSchedule_App_Success() throws Exception {
        ScheduleRequestDto requestDto = new ScheduleRequestDto();
        requestDto.setSchName("Hospital Visit");
        requestDto.setSchTime(LocalDateTime.now().plusDays(1));
        requestDto.setSchMemo("Checkup");
        requestDto.setPetNo(petA.getPetNo()); // UserA's Pet

        mockMvc.perform(post("/api/schedules")
                        .header("Authorization", "Bearer " + tokenUserA)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(requestDto)))
                .andExpect(status().isOk());
    }

    @Test
    @DisplayName("[App] 권한 실패: 보호자가 타인의 펫 일정 등록")
    void createSchedule_App_Forbidden_OtherPet() throws Exception {
        ScheduleRequestDto requestDto = new ScheduleRequestDto();
        requestDto.setSchName("Stolen Schedule");
        requestDto.setSchTime(LocalDateTime.now().plusDays(1));
        requestDto.setPetNo(petB.getPetNo()); // UserA tries to add for PetB

        mockMvc.perform(post("/api/schedules")
                        .header("Authorization", "Bearer " + tokenUserA)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(requestDto)))
                .andExpect(status().isForbidden()); // Expect 403
    }

    @Test
    @DisplayName("[Display] 정상 등록: 로그인 없이 기기에서 일정 등록 (Display Mode uses petId)")
    void createSchedule_Display_Success() throws Exception {
        ScheduleRequestDto requestDto = new ScheduleRequestDto();
        requestDto.setSchName("Display Schedule");
        requestDto.setSchTime(LocalDateTime.now().plusDays(2));
        requestDto.setPetId(petA.getPetId()); // Use petId for display mode

        // No Authorization Header
        mockMvc.perform(post("/api/schedules")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(requestDto)))
                .andExpect(status().isOk());
    }

    @Test
    @DisplayName("[App] 조회: 내 펫의 일정만 조회")
    void listSchedule_App_Success() throws Exception {
        // Given: Existing schedule for Pet A
        createScheduleFor(petA, "Pet A Schedule");

        mockMvc.perform(get("/api/schedules")
                        .header("Authorization", "Bearer " + tokenUserA)
                        .param("petNo", String.valueOf(petA.getPetNo())))
                .andExpect(status().isOk());
    }

    @Test
    @DisplayName("[App] 조회 실패: 남의 펫 일정 조회 시도")
    void listSchedule_App_Forbidden() throws Exception {
        mockMvc.perform(get("/api/schedules")
                        .header("Authorization", "Bearer " + tokenUserA)
                        .param("petNo", String.valueOf(petB.getPetNo()))) // Accessing PetB
                .andExpect(status().isForbidden());
    }

    private void createScheduleFor(Pet pet, String name) {
        com.noill.domain.schedule.entity.Schedule s = new com.noill.domain.schedule.entity.Schedule();
        s.setPet(pet);
        s.setSchName(name);
        s.setSchTime(LocalDateTime.now().plusDays(1));
        s.setSchStatus("Y"); // 이 값이 확실히 들어가는지 확인
        s.setSchMemo("Test Memo"); // nullable이더라도 값을 넣어주는 것이 안전합니다.
        scheduleRepository.save(s);
    }
}
