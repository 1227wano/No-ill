package com.noill.domain.pet.entity;

import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "pets")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Pet {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, length = 50)
    private String petNo;

    @Column(nullable = false, length = 100)
    private String name;

    @Builder
    public Pet(String petNo, String name) {
        this.petNo = petNo;
        this.name = name;
    }

    public void updateName(String name) {
        this.name = name;
    }
}
