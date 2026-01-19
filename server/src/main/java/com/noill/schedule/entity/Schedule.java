package com.noill.schedule.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.Future;
import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.SQLRestriction;
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
// 조회 시 자동으로 삭제되지 않은(Y) 데이터만 가져오도록 필터링 (Hibernate 6.3+)
@SQLRestriction("SCH_STATUS = 'Y'")
public class Schedule {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "USER_NO", nullable = false)
    private Integer userNo;

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

    /**
     * 논리적 삭제
     * 실제 DB에서 지우지 않고 상태만 'N'으로 변경합니다.
     */
    public void deleteLogic() {
        this.schStatus = "N";
    }
}
