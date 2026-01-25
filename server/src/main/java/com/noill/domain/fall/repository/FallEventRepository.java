package com.noill.domain.fall.repository;

import com.noill.domain.fall.entity.FallEvent;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface FallEventRepository extends JpaRepository<FallEvent, Long> {
    List<FallEvent> findByPetIdOrderByDetectedAtDesc(Long petId);
}
