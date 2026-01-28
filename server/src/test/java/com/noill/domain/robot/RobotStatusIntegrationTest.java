package com.noill.domain.robot;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.noill.domain.robot.dto.RobotStatusRequestDto;
import com.noill.domain.user.dto.SignupRequest;
import com.noill.domain.user.entity.User;
import com.noill.global.redis.RedisService;
import com.noill.domain.schedule.service.LlmService;
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

import java.util.UUID;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultHandlers.print;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
public class RobotStatusIntegrationTest {

        @Autowired
        private MockMvc mockMvc;

        @Autowired
        private ObjectMapper objectMapper;

        @MockBean
        private RedisService redisService;

        @MockBean
        private LlmService llmService;

        private String getAccessToken() throws Exception {
                String uniqueId = "robot_" + UUID.randomUUID().toString().substring(0, 8);

                SignupRequest signupRequest = new SignupRequest();
                signupRequest.setUserId(uniqueId);
                signupRequest.setUserPassword("Password123!");
                signupRequest.setUserName("RobotTester");
                signupRequest.setUserAddress("TestAddress");
                signupRequest.setUserPhone("010-0000-0000");
                signupRequest.setUserFamilyPhone("010-1111-1111");
                signupRequest.setUserName("RobotTester_U");

                try {
                        mockMvc.perform(post("/api/auth/signup")
                                        .contentType(MediaType.APPLICATION_JSON)
                                        .content(objectMapper.writeValueAsString(signupRequest)));
                } catch (Exception e) {
                        // Ignore
                }

                String loginJson = String.format("{\"userId\":\"%s\", \"userPassword\":\"Password123!\"}", uniqueId);

                MvcResult loginResult = mockMvc.perform(post("/api/auth/login")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(loginJson))
                                .andExpect(status().isOk())
                                .andReturn();

                return objectMapper.readTree(loginResult.getResponse().getContentAsString())
                                .get("data").get("accessToken").asText();
        }

        @Test
        @DisplayName("로봇 상태 조회 및 변경 통합 테스트 (PATROL <-> TRACK)")
        void testRobotStatusLifecycle() throws Exception {
                // 1. 토큰 발급 (로그인)
                String token = getAccessToken();

                // 2. 초기 상태 조회 (Default: PATROL)
                mockMvc.perform(get("/api/robot/status")
                                .header("Authorization", "Bearer " + token))
                                .andDo(print())
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$.status").value("PATROL"));

                // 3. 상태 변경 요청 (PATROL -> TRACK)
                RobotStatusRequestDto requestDto = new RobotStatusRequestDto();
                requestDto.setStatus("TRACK");

                mockMvc.perform(post("/api/robot/status")
                                .header("Authorization", "Bearer " + token)
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(objectMapper.writeValueAsString(requestDto)))
                                .andDo(print())
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$.status").value("TRACK"));

                // 4. 변경된 상태 확인 (GET)
                mockMvc.perform(get("/api/robot/status")
                                .header("Authorization", "Bearer " + token))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$.status").value("TRACK"));

                // 5. 다시 PATROL로 변경 시도
                requestDto.setStatus("PATROL");
                mockMvc.perform(post("/api/robot/status")
                                .header("Authorization", "Bearer " + token)
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(objectMapper.writeValueAsString(requestDto)))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$.status").value("PATROL"));
        }
}
