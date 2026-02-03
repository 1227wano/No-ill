package com.noill.domain.care.repository;

import com.noill.domain.care.entity.Care;
import com.noill.domain.care.entity.CareId;
import com.noill.domain.user.entity.User;
import com.noill.domain.pet.entity.Pet;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface CareRepository extends JpaRepository<Care, CareId> {

    // 내가 보호하고 있는 모든 펫 관계 조회
    @EntityGraph(attributePaths = "pet") // 1+N문제 해결

    List<Care> findByUser(User user);

    // 특정 펫을 보호하고 있는 모든 보호자 조회
    List<Care> findByPet(Pet pet);

    // 중복 등록 방지용: 내가 이미 이 펫을 등록했는지 확인
    boolean existsByUserAndPet(User user, Pet pet);

    // 특정 펫에 대해 내가 설정한 관계 조회
    Optional<Care> findByUserAndPet(User user, Pet pet);
}
