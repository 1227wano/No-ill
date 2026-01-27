
package com.noill.domain.schedule;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.noill.domain.user.dto.SignupRequest;
import com.noill.domain.user.entity.User;
import com.noill.global.redis.RedisService;
import com.noill.domain.schedule.dto.ScheduleRequestDto;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import java.time.LocalDateTime;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultHandlers.print;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
public class ScheduleIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private RedisService redisService;

    @MockBean
    private com.noill.domain.schedule.service.LlmService llmService;

    @Test
    @DisplayName("회원가입 -> 로그인 -> 일정 생성 전체 흐름 테스트")
    void createScheduleFlowTest() throws Exception {
        // ... (기존 코드 유지) ...
        // 1. 회원가입 (Sign Up)
        SignupRequest signupRequest = new SignupRequest();
        signupRequest.setUserId("testuser999");
        signupRequest.setUserPassword("Password123!");
        signupRequest.setUserName("테스트유저");
        signupRequest.setUserAddress("서울시 테스트구");
        signupRequest.setUserPhone("010-0000-0000");
        signupRequest.setUserFamilyPhone("010-1111-1111");
        signupRequest.setUserType(User.UserType.U);

        mockMvc.perform(post("/api/auth/signup")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(signupRequest)))
                .andDo(print())
                .andExpect(status().isCreated()); // 201 Created 확인

        // 2. 로그인 및 토큰 발급 (Login)
        String loginJson = """
                    {
                        "userId": "testuser999",
                        "userPassword": "Password123!"
                    }
                """;

        MvcResult loginResult = mockMvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(loginJson)) // JSON 문자열 전달
                .andDo(print())
                .andExpect(status().isOk())
                .andReturn();

        // 토큰 추출
        String responseBody = loginResult.getResponse().getContentAsString();
        JsonNode jsonNode = objectMapper.readTree(responseBody);
        String accessToken = jsonNode.get("data").get("accessToken").asText();

        System.out.println(">>> 발급된 토큰: " + accessToken);

        // 3. 일정 생성 (Create Schedule) - userNo 없이 토큰만으로 요청
        ScheduleRequestDto scheduleRequest = new ScheduleRequestDto();
        scheduleRequest.setSchName("통합 테스트 일정");
        scheduleRequest.setSchTime(LocalDateTime.now().plusDays(1)); // 내일
        scheduleRequest.setSchMemo("테스트 코드로 생성된 일정입니다.");

        mockMvc.perform(post("/api/schedules")
                .header("Authorization", "Bearer " + accessToken) // 토큰 헤더 추가
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(scheduleRequest)))
                .andDo(print())
                .andExpect(status().isOk()) // 200 OK 확인
                .andExpect(jsonPath("$.schName").value("통합 테스트 일정")) // 응답 데이터 검증
                .andExpect(jsonPath("$.userNo").exists()); // userNo가 응답에 포함되었는지 확인
    }

    @Test
    @DisplayName("LLM 연동 일정 등록 통합 테스트 (Mock API 호출)")
    void createScheduleWithLlm() throws Exception {
        // 1. 회원가입 (Sign Up)
        SignupRequest signupRequest = new SignupRequest();
        signupRequest.setUserId("llmuser1");
        signupRequest.setUserPassword("Password123!");
        signupRequest.setUserName("LLM유저");
        signupRequest.setUserAddress("서울시 강남구");
        signupRequest.setUserPhone("010-1234-5678");
        signupRequest.setUserFamilyPhone("010-9876-5432");
        signupRequest.setUserType(User.UserType.U);

        mockMvc.perform(post("/api/auth/signup")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(signupRequest)))
                .andExpect(status().isCreated());

        // 2. 로그인 (Login)
        String loginJson = """
                    {
                        "userId": "llmuser1",
                        "userPassword": "Password123!"
                    }
                """;
        MvcResult loginResult = mockMvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(loginJson))
                .andExpect(status().isOk())
                .andReturn();

        String accessToken = objectMapper.readTree(loginResult.getResponse().getContentAsString())
                .get("data").get("accessToken").asText();

        System.out.println(">>> LLM 테스트용 토큰 발급 완료");

        // Mock LlmService 설정
        com.noill.domain.schedule.dto.ScheduleAnalysisResponseDto mockResponse = new com.noill.domain.schedule.dto.ScheduleAnalysisResponseDto();
        com.noill.domain.schedule.dto.ScheduleAnalysisResponseDto.Command cmd = new com.noill.domain.schedule.dto.ScheduleAnalysisResponseDto.Command();
        cmd.setCmdType("add_schedule");
        cmd.setTitle("회식");
        cmd.setDatetime(LocalDateTime.now().plusDays(1).withHour(18).withMinute(0).toString()); // 내일 오후 6시
        cmd.setMemo("장소: 강남역, 내용: 회식");
        mockResponse.setCmd(cmd);
        mockResponse.setMessage("네, 내일 오후 6시에 강남역에서 회식 일정 등록했어요.");

        org.mockito.BDDMockito.given(llmService.analyzeUserCommand(org.mockito.ArgumentMatchers.anyString()))
                .willReturn(mockResponse);

        // 3. LLM 명령 전송 (Command)
        String commandText = "내일 오후 6시에 강남역에서 회식 있어";
        String commandJson = "{\"text\": \"" + commandText + "\"}";

        System.out.println(">>> LLM 요청 전송: " + commandText);

        MvcResult commandResult = mockMvc.perform(post("/api/schedules/command")
                .header("Authorization", "Bearer " + accessToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(commandJson))
                .andDo(print())
                .andExpect(status().isOk())
                .andReturn();

        String responseContent = commandResult.getResponse().getContentAsString();
        System.out.println(">>> LLM 응답 결과: " + responseContent);

        // 4. DB 저장 확인 (Verification)
        mockMvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders
                .get("/api/schedules")
                .header("Authorization", "Bearer " + accessToken))
                .andDo(print())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[-1].schName").value("회식"))
                .andExpect(jsonPath("$[-1].schMemo").value("장소: 강남역, 내용: 회식"));
    }
}
