package com.noill.domain.openvidu.controller;

import com.noill.domain.care.entity.Care;
import com.noill.domain.care.repository.CareRepository;
import com.noill.domain.notification.entity.FcmToken;
import com.noill.domain.notification.repository.FcmTokenRepository;
import com.noill.domain.notification.service.FcmService;
import com.noill.domain.pet.entity.Pet;
import com.noill.domain.pet.repository.PetRepository;
import com.noill.domain.user.entity.User;
import com.noill.domain.user.repository.UserRepository;
import com.noill.global.redis.RedisService;
import io.openvidu.java.client.*;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.Set;

@Tag(name = "OpenVidu API", description = "영상통화(WebRTC) 관련 API")
@RestController
@RequestMapping("/api/openvidu")
@RequiredArgsConstructor
@Slf4j
@SecurityRequirement(name = "jwtToken")
public class OpenViduController {

    @Value("${openvidu.url}")
    private String openviduUrl;

    @Value("${openvidu.secret}")
    private String openviduSecret;

    private OpenVidu openVidu;

    private final FcmService fcmService;
    private final PetRepository petRepository;
    private final RedisService redisService;

    private final UserRepository userRepository;
    private final FcmTokenRepository fcmTokenRepository;

    private final CareRepository careRepository;

    @PostConstruct
    public void init() {
        this.openVidu = new OpenVidu(openviduUrl, openviduSecret);
    }

    /**
     * 1. 세션(방) 생성
     * 보호자가 "전화 걸기"를 누르면 호출됩니다.
     *
     * @return 생성된 세션 ID
     */
    @Operation(summary = "세션(방) 생성", description = "보호자가 '전화 걸기'를 누르면 호출되어 OpenVidu 세션을 생성합니다.")
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
     *
     * @return 입장 토큰
     */
    @Operation(summary = "토큰(입장권) 발급", description = "세션 ID로 해당 방에 입장할 수 있는 암호화된 토큰을 발급합니다.")
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

    @Operation(summary = "로봇펫에게 영상통화 호출", description = "보호자가 로봇펫에게 FCM을 통해 영상통화 호출 신호를 보냅니다.")
    @PostMapping("/call/pet")
    public ResponseEntity<String> callPet(@RequestBody Map<String, String> request) {
        String petId = request.get("petId");         // 누구한테 걸지
        String sessionId = request.get("sessionId"); // 어느 방으로 오라 할지

        log.info("📞 [callPet] 요청 수신 - petId: {}, sessionId: {}", petId, sessionId);

        // 입력값 검증
        if (petId == null || petId.isBlank()) {
            log.warn("❌ [callPet] petId 누락");
            return ResponseEntity.badRequest().body("petId는 필수 값입니다.");
        }
        if (sessionId == null || sessionId.isBlank()) {
            log.warn("❌ [callPet] sessionId 누락");
            return ResponseEntity.badRequest().body("sessionId는 필수 값입니다.");
        }

        // 1. 펫 조회
        Pet pet = petRepository.findByPetId(petId)
                .orElseThrow(() -> {
                    log.error("❌ [callPet] 존재하지 않는 펫: {}", petId);
                    return new IllegalArgumentException("존재하지 않는 펫입니다.");
                });
        log.info("✅ [callPet] 펫 조회 성공: {}", pet.getPetId());

        // 2. 펫의 FCM 토큰들(Set) 조회
        String fcmKey = "FCM:PET:" + petId;
        Set<Object> members = redisService.getSetMembers(fcmKey);

        int successCount = 0;
        int invalidCount = 0;
        if (members != null && !members.isEmpty()) {
            for (Object m : members) {
                if (!(m instanceof String token)) continue;
                if (token.isBlank()) continue;

                FcmService.SendResult result = fcmService.sendVideoCallWakeUp(token, sessionId);
                if (result.success()) {
                    successCount++;
                } else if (result.invalidToken()) {
                    invalidCount++;
                    redisService.removeFromSet(fcmKey, token);
                }
            }
        } else {
            String singleToken = redisService.getValues(fcmKey);
            if (singleToken != null && !singleToken.isBlank()) {
                FcmService.SendResult result = fcmService.sendVideoCallWakeUp(singleToken, sessionId);
                if (result.success()) {
                    successCount = 1;
                }
            }
        }

        if (successCount == 0) {
            log.warn("⚠️ [callPet] FCM 전송 성공 0건 - petId: {}, sessionId: {}, invalidRemoved: {}", petId, sessionId, invalidCount);
            return ResponseEntity.status(HttpStatus.BAD_GATEWAY)
                    .body("호출 신호 전송에 실패했습니다. (invalidRemoved=" + invalidCount + ")");
        }

        log.info("✅ [callPet] 호출 완료 - petId: {}, sessionId: {}, success: {}, invalidRemoved: {}",
                petId, sessionId, successCount, invalidCount);

        return ResponseEntity.ok("호출 신호를 보냈습니다. success=" + successCount + ", invalidRemoved=" + invalidCount);
    }

    @Operation(summary = "보호자에게 영상통화 호출", description = "로봇펫이 보호자의 모든 기기에 FCM을 통해 영상통화 호출 신호를 보냅니다.")
    @PostMapping("/call/user")
    public ResponseEntity<String> callUser(@RequestBody Map<String, String> request) {
        String userId = request.get("userId");
        String sessionId = request.get("sessionId");

        // 입력값 검증
        if (userId == null || userId.isBlank()) {
            return ResponseEntity.badRequest().body("userId는 필수 값입니다.");
        }
        if (sessionId == null || sessionId.isBlank()) {
            return ResponseEntity.badRequest().body("sessionId는 필수 값입니다.");
        }

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

        log.info("{} 요청, {}대의 보호자 기기에 호출 신호를 보냈습니다.", userId, successCount);
        return ResponseEntity.ok(successCount + "대의 보호자 기기에 호출 신호를 보냈습니다.");
    }


    @Operation(
            summary = "보호자에게 영상통화 호출(펫 기준, 전원)",
            description = "로봇펫이 자신의 Care 관계를 기반으로 연결된 보호자 전원의 모든 기기에 FCM 호출 신호를 보냅니다."
    )
    @PostMapping("/call/users-by-pet")
    public ResponseEntity<String> callUsersByPet(@RequestBody Map<String, String> request,
                                                 Authentication authentication) {
        String sessionId = request.get("sessionId");

        if (sessionId == null || sessionId.isBlank()) {
            return ResponseEntity.badRequest().body("sessionId는 필수 값입니다.");
        }
        if (authentication == null || !authentication.isAuthenticated()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("인증이 필요합니다.");
        }

        Object principal = authentication.getPrincipal();
        if (!(principal instanceof String petId) || petId.isBlank()) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Pet 전용 API입니다.");
        }

        Pet pet = petRepository.findByPetId(petId)
                .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 펫입니다. petId=" + petId));

        List<Care> cares = careRepository.findByPet(pet);
        if (cares.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("연결된 보호자가 없습니다.");
        }

        int deviceSuccess = 0;
        int userCount = 0;

        for (Care care : cares) {
            User user = care.getUser();
            userCount++;

            List<FcmToken> tokens = fcmTokenRepository.findByUser(user);
            for (FcmToken tokenEntity : tokens) {
                FcmService.SendResult result = fcmService.sendVideoCallWakeUp(tokenEntity.getToken(), sessionId);
                if (result.success()) {
                    deviceSuccess++;
                }
                // invalidToken 정리(DB 삭제)는 원하면 추가로 넣을 수 있음
            }
        }

        if (deviceSuccess == 0) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body("보호자의 등록된 기기(토큰)가 없습니다.");
        }

        log.info("✅ [callUsersByPet] petId={}, sessionId={}, users={}, successDevices={}",
                petId, sessionId, userCount, deviceSuccess);

        return ResponseEntity.ok("보호자 호출 신호를 보냈습니다. users=" + userCount + ", devices=" + deviceSuccess);
    }
}
