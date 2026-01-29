package com.noill.domain.conversation.entity;

import com.noill.domain.pet.entity.Pet;
import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;

@Entity
@Table(name = "TALKS")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
@EntityListeners(AuditingEntityListener.class)
public class Talk {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "TALK_NO")
    private Long talkNo;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "PET_NO", nullable = false)
    private Pet pet;

    @Builder.Default
    @Column(name = "TALK_NAME", nullable = false, length = 100)
    private String talkName = "새로운 대화";

    @Builder.Default
    @Column(name = "STATUS", nullable = false, columnDefinition = "CHAR(1)")
    private String status = "Y";

    @CreatedDate
    @Column(name = "CREATED_AT", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    // --- 비즈니스 로직 ---
    public void close() {
        this.status = "N";
    }

    public void updateTitle(String newTitle) {
        this.talkName = newTitle;
    }
}
