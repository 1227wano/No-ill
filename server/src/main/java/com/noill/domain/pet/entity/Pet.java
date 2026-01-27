package com.noill.domain.pet.entity;

import com.noill.domain.care.entity.Care;
import com.noill.domain.user.entity.User;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "pets")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Pet {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "PET_NO")
    private Long petNo;

    @OneToMany(mappedBy = "pet", cascade = CascadeType.ALL)
    private List<Care> cares = new ArrayList<>();

    @Column(name = "PET_ID", nullable = false, length = 100, unique = true)
    private String petId;

    @Column(name = "PET_NAME", nullable = false, length = 100)
    private String petName;

    @Column(name = "PET_ADDRESS", nullable = false, length = 100)
    private String petAddress;

    @Column(name = "PET_PHONE", nullable = false, length = 100)
    private String petPhone;

    @Column(name = "PET_OWNER", nullable = false, length = 100)
    private String petOwner;

    @Column(name = "PET_BIRTH")
    private LocalDateTime petBirth;

    @Builder
    public Pet(String petId, String petName, String petAddress, String petPhone, String petOwner, LocalDateTime petBirth) {
        this.petId = petId;
        this.petName = petName;
        this.petAddress = petAddress;
        this.petPhone = petPhone;
        this.petOwner = petOwner;
        this.petBirth = petBirth;
    }
}
