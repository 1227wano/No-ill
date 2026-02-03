package com.noill.domain.openvidu.controller;

import com.noill.domain.notification.entity.FcmToken;
import com.noill.domain.notification.repository.FcmTokenRepository;
import com.noill.domain.notification.service.FcmService;
import com.noill.domain.pet.entity.Pet;
import com.noill.domain.pet.repository.PetRepository;
import com.noill.domain.user.entity.User;
import com.noill.domain.user.repository.UserRepository;
import com.noill.global.redis.RedisService;
import io.openvidu.java.client.*;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/openvidu")
@RequiredArgsConstructor
@Slf4j
public class OpenViduController {

    @Value("${openvidu.url}")
    private String openviduUrl;

    @Value("${openvidu.secret}")
    private String openviduSecret;

    private OpenVidu openVidu;
    private final FcmService fcmService;
    private final PetRepository petRepository;
    private final RedisService redisService;
    private final UserRepository userRepository;         // User 존재 확인용
    private final FcmTokenRepository fcmTokenRepository;

    // 서버가 켜질 때 OpenVidu 객체 초기화
    @PostConstruct
    public void init() {
        this.openVidu = new OpenVidu(openviduUrl, openviduSecret);
    }

    /**
     * 1. 세션(방) 생성
     * 보호자가 "전화 걸기"를 누르면 호출됩니다.
     * @return 생성된 세션 ID
     */
    @PostMapping("/sessions")
    public ResponseEntity<String> initializeSession(@RequestBody(required = false) Map<String, Object> params)
            throws OpenViduJavaClientException, OpenViduHttpException {

        // 세션 속성 설정 (기본값 사용)
        SessionProperties properties = SessionProperties.fromJson(params).build();

        // OpenVidu 서버에 세션 생성 요청
        Session session = openVidu.createSession(properties);

        return new ResponseEntity<>(session.getSessionId(), HttpStatus.OK);
    }

    /**
     * 2. 토큰(입장권) 발급
     * 세션 ID를 가지고 이 API를 호출하면, 해당 방에 들어갈 수 있는 암호화된 토큰을 줍니다.
     * 보호자도 호출하고, 로봇펫도 호출합니다.
     * @return 입장 토큰
     */
    @PostMapping("/sessions/{sessionId}/connections")
    public ResponseEntity<String> createConnection(@PathVariable("sessionId") String sessionId,
                                                   @RequestBody(required = false) Map<String, Object> params)
            throws OpenViduJavaClientException, OpenViduHttpException {

        // 1. 활성화된 세션 찾기
        Session session = openVidu.getActiveSession(sessionId);
        if (session == null) {
            return new ResponseEntity<>("세션을 찾을 수 없습니다.", HttpStatus.NOT_FOUND);
        }

        // 2. 연결 속성 설정
        ConnectionProperties properties = ConnectionProperties.fromJson(params).build();

        // 3. 토큰 발급 요청
        Connection connection = session.createConnection(properties);

        return new ResponseEntity<>(connection.getToken(), HttpStatus.OK);
    }

    @PostMapping("/call/pet")
    public ResponseEntity<String> callPet(@RequestBody Map<String, String> request) {
        String petId = request.get("petId");         // 누구한테 걸지
        String sessionId = request.get("sessionId"); // 어느 방으로 오라 할지

        // 1. 펫 조회
        Pet pet = petRepository.findByPetId(petId)
                .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 펫입니다."));

        // 2. 펫의 FCM 토큰 조회
        // Pet 엔티티에 fcmToken 필드가 있거나, FcmTokenRepository에서 조회
        String petFcmToken = redisService.getValues("FCM:PET:" + petId);

        // 3. FCM 전송
        fcmService.sendVideoCallWakeUp(petFcmToken, sessionId);

        return ResponseEntity.ok("호출 신호를 보냈습니다.");
    }

    @PostMapping("/call/user")
    public ResponseEntity<String> callUser(@RequestBody Map<String, String> request) {
        String userId = request.get("userId");
        String sessionId = request.get("sessionId");

        // 1. User 검증
        User user = userRepository.findByUserId(userId)
                .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 유저 ID입니다."));

        // 2. 보호자의 모든 토큰 조회
        List<FcmToken> tokens = fcmTokenRepository.findByUser(user);

        if (tokens.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body("보호자의 등록된 기기(토큰)가 없습니다.");
        }

        // 3. 모든 기기에 FCM 전송
        int successCount = 0;
        for (FcmToken tokenEntity : tokens) {
            // 각 토큰별로 알림 발송
            fcmService.sendVideoCallWakeUp(tokenEntity.getToken(), sessionId);
            successCount++;
        }

        return ResponseEntity.ok(successCount + "대의 보호자 기기에 호출 신호를 보냈습니다.");
    }
}
