package com.noill.domain.event.service;

import com.noill.domain.care.entity.Care;
import com.noill.domain.event.entity.Event;
import com.noill.domain.event.repository.EventRepository;
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
    // private final FcmService fcmService; // FCM

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

        for (Care care : cares) {
            User user = care.getUser();
            log.info("보호자({})에게 낙상 알림 전송 로직 수행", user.getUsername());
            // TODO: FCM 전송 로직 호출
        }
    }

    private void sendPushToUser(User user, String petName) {
        // TODO: User와 연결된 Token을 조회하여 FCM 발송
        // Token 엔티티나 로직이 User에 없어서 주석으로 흐름만 작성합니다.
        // 예: List<Token> tokens = tokenRepository.findByUser(user);
        // for (Token token : tokens) {
        //      fcmService.send(token.getValue(), "낙상 감지", petName + " 로봇이 낙상을 감지했습니다!");
        // }
        log.info("FCM 발송 시도 - 대상: {}, 내용: {} 로봇 낙상 감지", user.getUsername(), petName);
    }
}
