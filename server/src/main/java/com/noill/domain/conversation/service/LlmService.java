package com.noill.domain.conversation.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.noill.domain.conversation.dto.LlmAnalysisResult;
import com.noill.domain.conversation.dto.LlmIntent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class LlmService {

  private final RestTemplate restTemplate;
  private final ObjectMapper objectMapper;

  @Value("${gms.api.url:https://gms.ssafy.io/gmsapi/api.openai.com/v1/responses}")
  private String apiUrl;

  @Value("${gms.api.key:dummy_key}")
  private String apiKey;

  @Value("${gms.model:gpt-4.1}")
  private String model;

  // TODO: 시스템 프롬프트 로딩 방식 고민 (파일 읽기 or 하드코딩) -> 일단 상수로 정의하되 추후 파일 로딩 고려
  private static final String SYSTEM_PROMPT = """
            [페르소나 / 상황]
            너는 독거 노인들의 정서 안정을 돕는 어시스턴스야.
            최우선 목표는 노인과의 소통이야.
            네 이름은 "노일" 혹은 "노일이"야.

            [캐릭터 성향]
            - 기본적으로 정중하고 부드러운 존댓말(해요체)을 사용한다.
            - 어르신의 말벗이자 비서로서 예의를 갖춘다.
            - 단, 위급하거나 매우 강조해야 할 때만 친근한 반말을 섞어 쓴다.
            - 답변은 간결하게 2~3문장으로 끝낸다.

            [말투]
            - 전체적으로 존댓말을 쓴다.
            - 주기적으로 안부를 묻는 말을 섞어 말한다.
      - 분위기는 유머러스하게 유지한다. 대체로 부드럽게 대화한다.

            [대화 및 명령어 규칙]
            모든 응답은 JSON 형식을 따릅니다.

            규칙 0: 일반 대화 (daily_talk)
            - 사용자의 발화가 일상적인 대화나 안부 인사일 경우 사용합니다.
            {
              "cmd": {
                 "cmdType": "daily_talk"
              },
              "message": "(자연어 응답)"
            }

            규칙 1: 일정 추가 (add_schedule)
            - 사용자가 특정 날짜/시간에 일정을 추가하려 할 때 사용합니다.
            - 현재 시간([현재 시간 정보] 참고)을 기준으로 날짜와 시간을 계산해야 합니다.
            {
              "cmd": {
                "cmdType": "add_schedule",
                "title": "일정 제목",
                "datetime": "YYYY-MM-DDTHH:mm:ss",
                "memo": "일정 내용(장소, 사람 등)을 요약하여 필수로 작성"
              },
              "message": "(일정 등록 확인 메시지)"
            }

            [Few-shot Examples]

            User: 내일 오후 2시에 병원 가야 돼.
            Assistant: {"cmd": {"cmdType": "add_schedule", "title": "병원 방문", "datetime": "2026-01-22T14:00:00", "memo": "병원 진료"}, "message": "네, 내일 오후 2시 병원 일정을 잡았어요."}

            User: 오늘 뭐 했어?
            Assistant: {"cmd": {"cmdType": "daily_talk"}, "message": "저는 하루 종일 어르신 기다리고 있었죠. 오늘 하루는 어떠셨어요?"}
            """;

  public LlmAnalysisResult analyzeUserCommand(String userText) {
    if (userText == null || userText.trim().isEmpty()) {
      throw new IllegalArgumentException("입력 텍스트가 비어있습니다.");
    }

    log.info("LLM 요청: {}", userText);

    try {
      // 1. 요청 페이로드 구성
      Map<String, Object> requestBody = new HashMap<>();
      requestBody.put("model", model);
      requestBody.put("input", createPrompt(userText));

      HttpHeaders headers = new HttpHeaders();
      headers.setContentType(MediaType.APPLICATION_JSON);
      headers.setBearerAuth(apiKey);

      HttpEntity<Map<String, Object>> entity = new HttpEntity<>(requestBody, headers);

      // 2. API 호출
      String responseString = restTemplate.postForObject(apiUrl, entity, String.class);
      log.info("LLM 원본 응답: {}", responseString);

      // 3. 파싱 (GMS/OpenAI 응답 구조 처리)
      // 응답 구조: { "output": [ { "content": [ { "text": "{ ... }" } ] } ] }
      JsonNode rootNode = objectMapper.readTree(responseString);

      // GMS/OpenAI 래퍼 구조에서 실제 알맹이 JSON 문자열 추출
      JsonNode textNode = rootNode
          .path("output")
          .path(0)
          .path("content")
          .path(0)
          .path("text");

      if (textNode.isMissingNode() || textNode.isNull()) {
        log.error("LLM 응답에서 text 필드를 찾을 수 없습니다: {}", responseString);
        throw new RuntimeException("LLM 응답 구조가 올바르지 않습니다.");
      }

      String realContentJson = textNode.asText();
      log.info("LLM 추출된 콘텐츠: {}", realContentJson);

      // 4. 추출한 JSON 문자열을 통해 LlmAnalysisResult 빌드
      return parseLlmResponse(realContentJson);

    } catch (JsonProcessingException e) {
      log.error("LLM 응답 파싱 실패", e);
      throw new RuntimeException("LLM 응답을 파싱할 수 없습니다.", e);
    } catch (Exception e) {
      log.error("LLM API 호출 중 오류 발생", e);
      throw new RuntimeException("LLM 서비스 오류", e);
    }
  }

  private LlmAnalysisResult parseLlmResponse(String jsonString) throws JsonProcessingException {
    JsonNode root = objectMapper.readTree(jsonString);

    String message = root.path("message").asText("");
    JsonNode cmdNode = root.path("cmd");
    String cmdType = cmdNode.path("cmdType").asText("daily_talk");

    LlmIntent intent = LlmIntent.fromCode(cmdType);

    LlmAnalysisResult.LlmAnalysisResultBuilder resultBuilder = LlmAnalysisResult.builder()
        .intent(intent)
        .content(message);

    if (intent == LlmIntent.SCHEDULE) {
      String title = cmdNode.path("title").asText("일정");
      String datetimeStr = cmdNode.path("datetime").asText();
      String memo = cmdNode.path("memo").asText("");

      LocalDateTime schTime = LocalDateTime.parse(datetimeStr);

      resultBuilder.scheduleData(LlmAnalysisResult.ScheduleData.builder()
          .schName(title)
          .schTime(schTime)
          .schMemo(memo)
          .build());
    }

    return resultBuilder.build();
  }

  private String createPrompt(String userText) {
    // 현재 시간 주입
    String currentTime = LocalDateTime.now().toString();

    return String.format("""
        %s

        [현재 시간 정보]
        %s

        User: %s
        Assistant:
        """, SYSTEM_PROMPT, currentTime, userText);
  }
}
