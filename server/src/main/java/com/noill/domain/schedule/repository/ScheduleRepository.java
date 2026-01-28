package com.noill.domain.schedule.repository;

import com.noill.domain.schedule.entity.Schedule;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.time.LocalDateTime;
import java.util.List;

/**
 * ScheduleRepository
 * Entity 패키지 변경으로 import가 수정되었습니다.
 *
 * @SQLRestriction 덕분에 findAll 등을 호출해도 자동으로 SCH_STATUS = 'Y'인 것만 조회됩니다.
 */
@Repository
public interface ScheduleRepository extends JpaRepository<Schedule, Long> {

    List<Schedule> findAllBySchTimeBetween(LocalDateTime start, LocalDateTime end);
}
