package com.noill.domain.notification.service;

import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import net.nurigo.sdk.NurigoApp;
import net.nurigo.sdk.message.model.Message;
import net.nurigo.sdk.message.request.SingleMessageSendingRequest;
import net.nurigo.sdk.message.service.DefaultMessageService;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
@Slf4j
@RequiredArgsConstructor
public class SmsService {

    @Value("${coolsms.api.key}")
    private String apiKey;

    @Value("${coolsms.api.secret}")
    private String apiSecret;

    @Value("${coolsms.api.sender}")
    private String fromNumber;

    private DefaultMessageService messageService;

    @PostConstruct
    public void init() {
        this.messageService = NurigoApp.INSTANCE.initialize(apiKey, apiSecret, "https://api.solapi.com");
    }

    public void sendSms(String to, String text) {
        try {
            Message message = new Message();
            // 발신번호
            message.setFrom(fromNumber);
            // 수신번호
            message.setTo(to);
            message.setText(text);

            // 전송 요청
            messageService.sendOne(new SingleMessageSendingRequest(message));

            log.info("[SMS 전송 성공] To: {}, Content: {}", to, text);

        } catch (Exception e) {
            log.error("[SMS 전송 실패] To: {}, Error: {}", to, e.getMessage());
        }
    }
}
