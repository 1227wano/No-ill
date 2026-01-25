package com.noill.domain.fall.controller;

import com.noill.common.ApiResponse;
import com.noill.domain.fall.dto.FallEventRequest;
import com.noill.domain.fall.entity.FallEvent;
import com.noill.domain.fall.service.FallEventService;
import com.noill.global.security.jwt.JwtTokenProvider;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@Tag(name = "Fall Event", description = "낙상 감지 API")
@RestController
@RequestMapping("/api/fall-events")
@RequiredArgsConstructor
public class FallEventController {

    private final FallEventService fallEventService;
    private final JwtTokenProvider jwtTokenProvider;

    @Operation(summary = "낙상 이벤트 생성", description = "로봇이 낙상을 감지했을 때 호출합니다.")
    @PostMapping
    public ResponseEntity<ApiResponse<Map<String, Long>>> createFallEvent(
            @RequestHeader("Authorization") String authorization,
            @Valid @RequestBody FallEventRequest request) {

        String token = authorization.replace("Bearer ", "");
        String petNo = jwtTokenProvider.getUsernameFromToken(token);

        FallEvent event = fallEventService.createFallEvent(petNo, request);

        return ResponseEntity.ok(ApiResponse.success(
                "낙상 이벤트가 생성되었습니다.",
                Map.of("eventId", event.getId())
        ));
    }

    @Operation(summary = "낙상 이벤트 상태 업데이트", description = "이벤트 상태를 업데이트합니다. (CONFIRMED, FALSE_ALARM)")
    @PatchMapping("/{eventId}/status")
    public ResponseEntity<ApiResponse<Void>> updateEventStatus(
            @PathVariable Long eventId,
            @RequestBody Map<String, String> request) {

        String status = request.get("status");
        fallEventService.updateEventStatus(eventId, status);

        return ResponseEntity.ok(ApiResponse.success("상태가 업데이트되었습니다."));
    }
}
