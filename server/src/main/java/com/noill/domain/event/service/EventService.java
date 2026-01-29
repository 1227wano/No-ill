package com.noill.domain.event.service;

import com.noill.domain.care.entity.Care;
import com.noill.domain.event.entity.Event;
import com.noill.domain.event.repository.EventRepository;
import com.noill.domain.notification.entity.FcmToken;
import com.noill.domain.notification.repository.FcmTokenRepository;
import com.noill.domain.notification.service.FcmService;
import com.noill.domain.pet.entity.Pet;
import com.noill.domain.pet.repository.PetRepository;
import com.noill.domain.user.entity.User;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class EventService {

    private final EventRepository eventRepository;
    private final PetRepository petRepository;

    // FCM
    private final FcmTokenRepository fcmTokenRepository;
    private final FcmService fcmService;

    @Transactional
    public void alertEvent(MultipartFile file) {
        // 1. 파일명 파싱 (.jpg 빼기)
        String originalFilename = file.getOriginalFilename();
        if (originalFilename == null || !originalFilename.contains(".")) {
            throw new IllegalArgumentException("유효하지 않은 파일명입니다.");
        }
        String petId = originalFilename.substring(0, originalFilename.lastIndexOf("."));

        // 2. Pet 조회
        Pet pet = petRepository.findByPetId(petId)
                .orElseThrow(() -> new IllegalArgumentException("등록되지 않은 펫 ID입니다: " + petId));

        // 3. 이벤트 DB 저장
        Event event = Event.builder()
                .pet(pet)
                .eventTime(LocalDateTime.now())
                .build();
        eventRepository.save(event);

        // 4. 보호자 조회 및 FCM 발송
        List<Care> cares = pet.getCares();
        if (cares.isEmpty()) {
            log.info("이 펫({})에 연결된 보호자가 없습니다.", pet.getPetName());
            return;
        }

        for (Care care : cares) {
            User user = care.getUser();
            sendPushToUser(user, care.getCareName(), file);
        }
    }

    private void sendPushToUser(User user, String careName, MultipartFile file) {
        // User의 토큰 조회
        List<FcmToken> tokens = fcmTokenRepository.findByUser(user);

        if (tokens.isEmpty()) {
            log.info("유저({})는 등록된 FCM 토큰이 없습니다.", user.getUsername());
            return;
        }

        String title = "낙상 감지 알림";
        String body = String.format("%s 님의 낙상을 감지했습니다! 확인해주세요.", careName);

        // 등록된 모든 기기(토큰)로 전송
        for (FcmToken fcmToken : tokens) {
            fcmService.sendNotification(fcmToken.getToken(), title, body, file);
        }

        log.info("보호자({})의 기기 {}대에 알림 전송 완료", user.getUsername(), tokens.size());
    }
}
