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
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class EventService {

    private final EventRepository eventRepository;
    private final PetRepository petRepository;
    private final FcmTokenRepository fcmTokenRepository;
    private final FcmService fcmService;

    // application.yml에서 주입받은 경로와 URL
    @Value("${file.dir}")
    private String fileDir;

    @Value("${server.url}")
    private String serverUrl;

    @Transactional
    public void alertEvent(MultipartFile file) {
        // 1. 파일명 및 확장자 파싱
        String originalFilename = file.getOriginalFilename();
        if (originalFilename == null || originalFilename.isEmpty()) {
            throw new IllegalArgumentException("파일명이 없습니다.");
        }

        // 확장자 추출
        String ext = extractExtension(originalFilename);
        // PetId 추출
        String petId = originalFilename.substring(0, originalFilename.lastIndexOf("."));

        // 2. 서버 디스크에 파일 저장
        String savedFileName = UUID.randomUUID() + ext; // 파일명 중복 방지 (uuid.jpg)
        String fullPath = fileDir + savedFileName;      // /app/images/uuid.jpg

        try {
            // 실제 파일 저장 실행
            file.transferTo(new File(fullPath));
            log.info("이미지 저장 성공: {}", fullPath);
        } catch (IOException e) {
            log.error("이미지 저장 실패", e);
            throw new RuntimeException("이미지 저장 중 오류 발생", e);
        }

        // 3. 외부에서 접근 가능한 이미지 URL 생성
        String imageUrl = serverUrl + "/images/" + savedFileName; // http://IP:8080/images/uuid.jpg
        log.info("생성된 이미지 URL: {}", imageUrl);

        // 4. Pet 조회
        Pet pet = petRepository.findByPetId(petId)
                .orElseThrow(() -> new IllegalArgumentException("등록되지 않은 펫 ID입니다: " + petId));

        Event event = Event.builder()
                .pet(pet)
                .eventTime(LocalDateTime.now())
                .build();
        eventRepository.save(event);

        List<Care> cares = pet.getCares();
        if (cares.isEmpty()) {
            log.info("이 펫({})에 연결된 보호자가 없습니다.", pet.getPetName());
            return;
        }

        for (Care care : cares) {
            User user = care.getUser();
            sendPushToUser(user, care.getCareName(), imageUrl);
        }
    }

    private void sendPushToUser(User user, String careName, String imageUrl) {
        List<FcmToken> tokens = fcmTokenRepository.findByUser(user);

        if (tokens.isEmpty()) {
            return;
        }

        String title = "낙상 감지 알림";
        String body = String.format("%s 님의 낙상을 감지했습니다! 확인해주세요.", careName);

        for (FcmToken fcmToken : tokens) {
            fcmService.sendNotification(fcmToken.getToken(), title, body, imageUrl);
        }
    }

    // 확장자 추출 헬퍼 메서드
    private String extractExtension(String originalFilename) {
        int pos = originalFilename.lastIndexOf(".");
        return (pos == -1) ? ".jpg" : originalFilename.substring(pos);
    }
}
