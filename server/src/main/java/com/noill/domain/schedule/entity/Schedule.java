package com.noill.domain.schedule.entity;

import com.noill.domain.pet.entity.Pet;
import jakarta.persistence.*;
import jakarta.validation.constraints.Future;
import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import java.time.LocalDateTime;

/**
 * Schedule Entity
 * 데이터베이스의 'Schedules' 테이블과 1:1로 매핑되는 클래스입니다.
 * JPA가 이 클래스를 보고 테이블을 자동으로 생성하거나 데이터를 매핑합니다.
 */
@Entity
@Table(name = "Schedules")
@Getter
@Setter
@NoArgsConstructor
public class Schedule {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "SCH_NO") // ERD의 '일정번호' 컬럼명 반영
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "PET_NO", nullable = false)
    private Pet pet;

    @NotBlank(message = "일정 이름은 필수입니다.")
    @Column(name = "SCH_NAME", length = 100, nullable = false)
    private String schName;

    @Future(message = "일정은 미래 시간이어야 합니다.")
    @Column(name = "SCH_TIME", nullable = false)
    private LocalDateTime schTime;

    @Column(name = "SCH_MEMO", length = 1000)
    private String schMemo;

    @Column(name = "SCH_STATUS", length = 1, nullable = false)
    private String schStatus = "Y";

    // --- 비즈니스 로직 메서드 ---

    /**
     * 일정 수정 (Dirty Checking 용)
     * Setter를 직접 호출하는 것보다, 의미 있는 메서드를 만들어 사용하는 것이 좋습니다.
     */
    public void update(String schName, String schMemo, LocalDateTime schTime) {
        this.schName = schName;
        this.schMemo = schMemo;
        this.schTime = schTime;
    }
}
