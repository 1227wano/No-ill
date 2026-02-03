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
import java.util.List;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class LlmService {

  private final RestTemplate restTemplate;
  private final ObjectMapper objectMapper;

  @Value("${gms.api.url:https://gms.ssafy.io/gmsapi/api.openai.com/v1/chat/completions}")
  private String apiUrl;

  @Value("${gms.api.key:dummy_key}")
  private String apiKey;

  @Value("${gms.model:gpt-4.1}")
  private String model;

  // 분석용 시스템 프롬프트 (JSON 응답)
  private static final String SYSTEM_PROMPT_ANALYSIS = """
      [페르소나 / 상황]
      너는 독거 노인들의 정서 안정을 돕는 어시스턴스야.
      최우선 목표는 노인과의 소통이야.
      네 이름은 "노일", "Noill" 또는 "노일이"야.

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
      - 사용자가 특정 날짜/시간의 일정을 말하지 않고, 일상적인 대화나 안부 인사일 경우 사용합니다.
      {
        "cmd": {
           "cmdType": "daily_talk"
        },
        "message": "(자연어 응답)"
      }

      규칙 1: 일정 추가 (add_schedule)
      - 사용자가 특정 날짜/시간에 일정을 추가하려 할 때 사용합니다.
      - 현재 시간(아래 정보 참고)을 기준으로 날짜와 시간을 계산해야 합니다.

      [현재 시간 정보]
      %s

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

      User: 내일 오후 2시에 병원 가야 돼. (현재 시간: 2026-01-21T10:00:00)
      Assistant: {"cmd": {"cmdType": "add_schedule", "title": "병원 방문", "datetime": "2026-01-22T14:00:00", "memo": "병원 진료"}, "message": "네, 내일 오후 2시 병원 일정을 잡았어요."}

      User: 오늘 뭐 했어?
      Assistant: {"cmd": {"cmdType": "daily_talk"}, "message": "저는 하루 종일 어르신 기다리고 있었죠. 오늘 하루는 어떠셨어요?"}
      """;

  // 요약용 시스템 프롬프트
  private static final String SYSTEM_PROMPT_SUMMARY = """
      [지시사항]
      다음 대화 내용을 읽고 **구체적인 사실 관계나 핵심 사건**을 포함하여 50자 이내로 요약해줘.
      예시: "아드님이 주말에 방문하여 김치찌개를 드심", "무릎 통증으로 내일 병원에 가기로 함"
      추상적인 표현(예: "일정 관리 대화", "기억 보조", "안부 인사")은 피하고, **누가 무엇을 했는지** 명확히 기록해.
      따옴표나 설명 없이 오직 '요약 텍스트'만 출력해.
      """;

  /**
   * 사용자 발화 의도 분석 (JSON 응답 파싱)
   */
  private static final String FALLBACK_MESSAGE = "죄송해요, 잠시 머리가 아파서 생각을 정리하는 중이에요. 조금 뒤에 다시 말씀해 주시겠어요?";

  /**
   * 사용자 발화 의도 분석 (JSON 응답 파싱) - Context Aware
   *
   * @param userText       사용자 발화
   * @param historyContext 최근 대화 내용 (Q/A)
   * @param memoryContext  관련 과거 기억 (Title)
   */
  public LlmAnalysisResult analyzeUserCommand(String userText, String historyContext, String memoryContext) {
    if (userText == null || userText.trim().isEmpty()) {
      return LlmAnalysisResult.builder()
          .intent(LlmIntent.UNKNOWN)
          .content("잘 못 들었어요. 다시 한 번 말씀해 주시겠어요?")
          .build();
    }

    String fullPrompt = createAnalysisPrompt(userText, historyContext, memoryContext);
    log.info("LLM 분석 요청: {}", userText);

    try {
      // 1. API 호출 (String 반환)
      String jsonResponse = callLlmApi(fullPrompt);
      log.info("LLM 분석 결과(Raw): {}", jsonResponse);

      // 2. JSON 파싱 및 DTO 변환
      return parseLlmResponse(jsonResponse);

    } catch (Exception e) {
      log.error("LLM 분석 중 오류 발생: {}", e.getMessage(), e);
      return LlmAnalysisResult.builder()
          .intent(LlmIntent.UNKNOWN)
          .content(FALLBACK_MESSAGE)
          .build();
    }
  }

  public LlmAnalysisResult analyzeUserCommand(String userText) {
    return analyzeUserCommand(userText, "", "");
  }

  /**
   * 대화 세션 제목 생성 (Plain Text 응답 사용)
   */
  public String generateSessionTitle(String conversationContext) {
    if (conversationContext == null || conversationContext.trim().isEmpty()) {
      return "새로운 대화";
    }

    String fullPrompt = String.format("%s\n\n[대화 내용]\n%s", SYSTEM_PROMPT_SUMMARY, conversationContext);
    log.info("LLM 요약 요청");

    try {
      // 1. API 호출
      String title = callLlmApi(fullPrompt);
      log.info("LLM 요약 결과: {}", title);

      // 2. 파싱 없이 텍스트 그대로 반환
      return title.trim().replace("\"", "");

    } catch (Exception e) {
      log.error("LLM 요약 중 오류 발생", e);
      return "일반 대화"; // Fallback 제목
    }
  }

  /**
   * LLM API 호출 및 원본 텍스트 추출
   * OpenAI Chat Completion API 규격에 맞춰 HTTP 요청을 구성하고,
   * 복잡한 JSON 응답 구조에서 실제 답변(content)만 안전하게 추출합니다.
   *
   * @param fullPrompt 시스템 지시사항과 대화 문맥이 모두 포함된 완성형 프롬프트
   * @return LLM이 생성한 순수 텍스트 응답 (JSON 파싱 전 상태)
   */
  private String callLlmApi(String fullPrompt) {
    // 1. 요청 Body 구성 (OpenAI API Standard)
    // 구조: {
    // "model": "gpt-4...",
    // "messages": [
    // { "role": "user", "content": "...(프롬프트 내용)..." }
    // ]
    // }
    Map<String, Object> requestBody = new HashMap<>();
    requestBody.put("model", model);

    // * 'messages'는 대화형 모델의 필수 파라미터입니다.
    List<Map<String, String>> messages = List.of(
        Map.of("role", "user", "content", fullPrompt));
    requestBody.put("messages", messages);

    // 2. HTTP 헤더 설정
    HttpHeaders headers = new HttpHeaders();
    headers.setContentType(MediaType.APPLICATION_JSON);
    headers.setBearerAuth(apiKey); // Authorization: Bearer <API_KEY>

    HttpEntity<Map<String, Object>> entity = new HttpEntity<>(requestBody, headers);

    // 3. API 호출 (Synchronous Blocking)
    String responseString = restTemplate.postForObject(apiUrl, entity, String.class);

    // 4. 응답 파싱 (Response Parsing)
    try {
      JsonNode rootNode = objectMapper.readTree(responseString);

      // 안전한 경로 탐색 (Null-safe Traversal)
      JsonNode contentNode = rootNode
          .path("choices")
          .path(0) // 첫 번째 후보 답변 선택
          .path("message")
          .path("content"); // 텍스트 내용 추출

      if (contentNode.isMissingNode() || contentNode.isNull()) {
        log.error("LLM 응답 규격 불일치 (Content 누락): {}", responseString);
        throw new RuntimeException("LLM API 응답 구조가 예상과 다릅니다. (choices[0].message.content 누락)");
      }

      return contentNode.asText();

    } catch (JsonProcessingException e) {
      throw new RuntimeException("API 응답 JSON 파싱 실패", e);
    }
  }

  private String createAnalysisPrompt(String userText, String historyContext, String memoryContext) {
    String currentTime = LocalDateTime.now().toString();

    // 1. 시스템 프롬프트 완성
    String systemInstruction = SYSTEM_PROMPT_ANALYSIS.formatted(currentTime);

    // 2. 전체 프롬프트 조립
    return String.format("""
        %s

        [관련된 과거 기억]
        %s

        [현재 대화 흐름]
        %s

        User: %s
        Assistant:
        """, systemInstruction, memoryContext, historyContext, userText);
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
}
