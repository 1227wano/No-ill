package com.noill.domain.conversation.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;

@Entity
@Table(name = "MESSAGES")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
@EntityListeners(AuditingEntityListener.class)
public class Message {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "MSG_NO")
    private Long msgNo;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "TALK_NO", nullable = false)
    private Talk talk;

    @Column(name = "MSG_TYPE", nullable = false, columnDefinition = "CHAR(1)")
    private String msgType; // 'Q' (User) or 'A' (Bot)

    @Column(name = "MSG_CONTENT", nullable = false, columnDefinition = "TEXT")
    private String msgContent;

    @CreatedDate
    @Column(name = "CREATED_AT", nullable = false, updatable = false)
    private LocalDateTime createdAt;
}
