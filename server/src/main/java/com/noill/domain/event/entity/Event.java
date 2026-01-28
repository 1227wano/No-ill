package com.noill.domain.event.entity;

import com.noill.domain.pet.entity.Pet;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

@Entity
@Table(name = "events")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Event {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "EVENT_NO")
    private Long eventNo;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "PET_NO", nullable = false)
    private Pet pet;

    @Column(name = "EVENT_TIME", nullable = false)
    private LocalDateTime eventTime;

    @Builder
    public Event(Pet pet, LocalDateTime eventTime) {
        this.pet = pet;
        this.eventTime = eventTime;
    }
}
