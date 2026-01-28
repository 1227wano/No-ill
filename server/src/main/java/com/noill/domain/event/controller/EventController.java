package com.noill.domain.event.controller;

import com.noill.domain.event.service.EventService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/events")
@RequiredArgsConstructor
@Slf4j
public class EventController {

    private final EventService eventService;

    @PostMapping(value = "/report", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<Void> reportEvent(@RequestParam("file") MultipartFile file) {
        log.info("파일 수신: {}, 크기: {}", file.getOriginalFilename(), file.getSize());

        eventService.alertEvent(file);

        return ResponseEntity.ok().build();
    }
}
