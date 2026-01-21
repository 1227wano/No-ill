package com.noill.domain.user.entity;

import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import java.util.Collection;
import java.util.Collections;

@Entity
@Table(name = "members")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class User implements UserDetails {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long userNo;

    @Column(nullable = false, unique = true, length = 100)
    private String userId;

    @Column(nullable = false, length = 100)
    private String userPassword;

    @Column(nullable = false, length = 100)
    private String userName;

    @Column(nullable = false, length = 1000)
    private String userAddress;

    @Column(nullable = false)
    private String userPhone;

    @Column()
    private String userFamily;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 1)
    private UserType userType;

    @Builder
    public User(String userId, String userPassword, String userName, String userAddress, String userPhone, String userFamily, UserType userType) {
        this.userId = userId;
        this.userPassword = userPassword;
        this.userName = userName;
        this.userAddress = userAddress;
        this.userPhone = userPhone;
        this.userFamily = userFamily;
        this.userType = userType;
    }

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return Collections.singletonList(new SimpleGrantedAuthority(this.userType.getKey()));
    }

    @Override
    public String getUsername() {
        return this.userId;
    }

    @Override
    public String getPassword() {
        return this.userPassword;
    }

    @Override
    public boolean isAccountNonExpired() {
        return true;
    }

    @Override
    public boolean isAccountNonLocked() {
        return true;
    }

    @Override
    public boolean isCredentialsNonExpired() {
        return true;
    }

    @Override
    public boolean isEnabled() {
        return true;
    }

    @Getter
    @RequiredArgsConstructor
    public enum UserType {
        U("ROLE_USER", "사용자"),
        F("ROLE_FAMILY", "보호자"),
        A("ROLE_ADMIN", "관리자");

        private final String key;
        private final String title;
    }
}
