package com.noill.domain.care.entity;

import com.noill.domain.pet.entity.Pet;
import com.noill.domain.user.entity.User;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EntityListeners;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.IdClass;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.time.LocalDateTime;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

@Entity
@Table(name = "cares")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@IdClass(CareId.class) // 복합키 클래스 매핑
@EntityListeners(AuditingEntityListener.class)
public class Care {

    @Id
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "USER_NO")
    private User user;

    @Id
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "PET_NO")
    private Pet pet;

    @Column(name = "CARE_NAME", nullable = false, length = 100)
    private String careName; // 보호자가 부르는 호칭

    @CreatedDate
    @Column(name = "CARE_START", nullable = false, updatable = false)
    private LocalDateTime careStart;

    @Builder
    public Care(User user, Pet pet, String careName, LocalDateTime careStart) {
        this.user = user;
        this.pet = pet;
        this.careName = careName;
        this.careStart = careStart;
    }

    public void updateCareName(String newName) {
        this.careName = newName;
    }
}
