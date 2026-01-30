package com.noill.domain.event.controller;

import com.noill.domain.event.service.EventService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@Tag(name = "Event API", description = "낙상 감지 API")
@RestController
@RequestMapping("/api/events")
@RequiredArgsConstructor
@Slf4j
public class EventController {

    private final EventService eventService;

    @Operation(summary = "낙상 감지 사진 전송", description = "낙상 감지시 로봇펫이 촬영항 사진을 수신하여 성공시 빈 값 반환")
    @PostMapping(value = "/report", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<Void> reportEvent(@RequestParam("file") MultipartFile file) {
        log.info("파일 수신: {}, 크기: {}", file.getOriginalFilename(), file.getSize());

        eventService.alertEvent(file);

        return ResponseEntity.ok().build();
    }
}
