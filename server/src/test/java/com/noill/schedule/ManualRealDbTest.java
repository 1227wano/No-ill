package com.noill.schedule;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.noill.domain.user.dto.SignupRequest;
import com.noill.domain.user.entity.User;
import org.junit.jupiter.api.Disabled;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.annotation.Commit;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultHandlers.print;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@Disabled("실제 DB에 데이터를 넣는 수동 테스트입니다. 필요 시 @Disabled를 주석 처리하고 실행하세요.")
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("dev") // 실제 DB 설정(MySQL)을 사용
@Transactional
@Commit // 테스트가 끝나도 롤백하지 않고 커밋함 (데이터 확인용)
public class ManualRealDbTest {

        @Autowired
        private MockMvc mockMvc;

        @Autowired
        private ObjectMapper objectMapper;

        @Test
        @DisplayName("실제 DB에 회원가입 및 LLM 일정 등록 테스트")
        void testRealDbInsert() throws Exception {
                // 1. 유니크한 회원 ID 생성 (중복 방지)
                String uniqueId = "real_user_" + System.currentTimeMillis();

                // 회원가입
                SignupRequest signupRequest = new SignupRequest();
                signupRequest.setUserId(uniqueId);
                signupRequest.setUserPassword("Password123!");
                signupRequest.setUserName("실제DB테스터");
                signupRequest.setUserAddress("서울시 테스트구");
                signupRequest.setUserPhone("010-" + (int) (Math.random() * 9000 + 1000) + "-1234");
                signupRequest.setUserFamilyPhone("010-1111-2222");
                signupRequest.setUserType(User.UserType.U);

                mockMvc.perform(post("/api/auth/signup")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(objectMapper.writeValueAsString(signupRequest)))
                                .andExpect(status().isCreated());

                System.out.println(">>> 회원가입 완료: " + uniqueId);

                // 로그인
                String loginJson = String.format("""
                                    {
                                        "userId": "%s",
                                        "userPassword": "Password123!"
                                    }
                                """, uniqueId);

                MvcResult loginResult = mockMvc.perform(post("/api/auth/login")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(loginJson))
                                .andExpect(status().isOk())
                                .andReturn();

                String accessToken = objectMapper.readTree(loginResult.getResponse().getContentAsString())
                                .get("data").get("accessToken").asText();

                System.out.println(">>> 토큰 발급 완료");

                // LLM 일정 등록 요청
                String commandText = "이번 주 금요일 저녁 7시에 팀 회식 있어";
                String commandJson = "{\"text\": \"" + commandText + "\"}";

                MvcResult commandResult = mockMvc.perform(post("/api/schedules/command")
                                .header("Authorization", "Bearer " + accessToken)
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(commandJson))
                                .andDo(print())
                                .andExpect(status().isOk())
                                .andReturn();

                System.out.println(">>> LLM 응답: " + commandResult.getResponse().getContentAsString());
                System.out.println(">>> 실제 DB(MySQL)를 확인해보세요! userId: " + uniqueId);
        }
}
