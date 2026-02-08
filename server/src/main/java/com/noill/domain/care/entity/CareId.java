package com.noill.domain.care.entity;

import lombok.AllArgsConstructor;
import lombok.EqualsAndHashCode;
import lombok.Getter;
import lombok.NoArgsConstructor;
import java.io.Serializable;

// 복합키 클래스 정의
@Getter
@NoArgsConstructor
@AllArgsConstructor
@EqualsAndHashCode
public class CareId implements Serializable {
    private Long user;
    private Long pet;
}
