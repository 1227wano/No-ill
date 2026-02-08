package com.noill.domain.event.repository;

import com.noill.domain.event.entity.Event;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface EventRepository extends JpaRepository<Event, Long> {
    List<Event> findAllByPet_PetIdOrderByEventTimeDesc(String petId);
}
