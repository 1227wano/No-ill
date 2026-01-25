package com.noill.domain.fall.entity;

import com.noill.domain.pet.entity.Pet;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "fall_events")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class FallEvent {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "pet_id", nullable = false)
    private Pet pet;

    @Column(nullable = false)
    private LocalDateTime detectedAt;

    @Column(columnDefinition = "LONGTEXT")
    private String imageBase64;

    @Column(length = 20)
    private String status; // DETECTED, CONFIRMED, FALSE_ALARM

    @Column(length = 100)
    private String location;

    private Double confidence;

    @Builder
    public FallEvent(Pet pet, LocalDateTime detectedAt, String imageBase64,
                     String status, String location, Double confidence) {
        this.pet = pet;
        this.detectedAt = detectedAt;
        this.imageBase64 = imageBase64;
        this.status = status;
        this.location = location;
        this.confidence = confidence;
    }

    public void updateStatus(String status) {
        this.status = status;
    }
}
