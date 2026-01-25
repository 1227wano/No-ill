package com.noill.domain.fall.service;

import com.noill.domain.fall.dto.FallAlertMessage;
import com.noill.domain.fall.dto.FallEventRequest;
import com.noill.domain.fall.entity.FallEvent;
import com.noill.domain.fall.repository.FallEventRepository;
import com.noill.domain.pet.entity.Pet;
import com.noill.domain.pet.repository.PetRepository;
import com.noill.global.websocket.FallAlertWebSocketHandler;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

@Slf4j
@Service
@RequiredArgsConstructor
public class FallEventService {

    private final FallEventRepository fallEventRepository;
    private final PetRepository petRepository;
    private final FallAlertWebSocketHandler webSocketHandler;

    @Transactional
    public FallEvent createFallEvent(String petNo, FallEventRequest request) {
        Pet pet = petRepository.findByPetNo(petNo)
                .orElseThrow(() -> new IllegalArgumentException("Pet not found: " + petNo));

        LocalDateTime detectedAt = LocalDateTime.now();

        FallEvent fallEvent = FallEvent.builder()
                .pet(pet)
                .detectedAt(detectedAt)
                .imageBase64(request.getImageBase64())
                .status("DETECTED")
                .location(request.getLocation())
                .confidence(request.getConfidence())
                .build();

        FallEvent savedEvent = fallEventRepository.save(fallEvent);
        log.info("Fall event created: id={}, petNo={}", savedEvent.getId(), petNo);

        // WebSocket으로 브로드캐스트
        FallAlertMessage alertMessage = FallAlertMessage.builder()
                .type("FALL_DETECTED")
                .eventId(savedEvent.getId())
                .detectedAt(detectedAt)
                .imageBase64(request.getImageBase64())
                .location(request.getLocation())
                .confidence(request.getConfidence())
                .petName(pet.getName())
                .message("낙상이 감지되었습니다!")
                .build();

        webSocketHandler.broadcast(alertMessage);
        log.info("Fall alert broadcasted to {} sessions", webSocketHandler.getActiveSessionCount());

        return savedEvent;
    }

    @Transactional
    public void updateEventStatus(Long eventId, String status) {
        FallEvent event = fallEventRepository.findById(eventId)
                .orElseThrow(() -> new IllegalArgumentException("Fall event not found: " + eventId));
        event.updateStatus(status);
        log.info("Fall event status updated: id={}, status={}", eventId, status);
    }
}
