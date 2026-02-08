package com.noill.domain.schedule.repository;

import com.noill.domain.schedule.entity.Schedule;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.time.LocalDateTime;
import java.util.List;

/**
 * ScheduleRepository
 * @SQLRestriction 덕분에 findAll 등을 호출해도 자동으로 SCH_STATUS = 'Y'인 것만 조회됩니다.
 */
@Repository
public interface ScheduleRepository extends JpaRepository<Schedule, Long> {

    // 사용자 일정만 조회 (FK: petNo)
    List<Schedule> findAllByPetPetNo(Long petNo);

    // 사용자의 날짜 범위 일정 조회
    List<Schedule> findAllByPetPetNoAndSchTimeBetween(Long petNo, LocalDateTime start, LocalDateTime end);
}
