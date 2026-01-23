package com.noill.domain.user.dto;

import com.noill.domain.user.entity.User.UserType;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class LoginResponse {

    private String accessToken;
    private String refreshToken;
    private String tokenType;
    private Long expiresIn;

    private String userName;
    private UserType userType;

    public static LoginResponse of(String accessToken, String refreshToken, Long expiresIn, String userName, UserType userType) {
        return LoginResponse.builder()
                .accessToken(accessToken)
                .refreshToken(refreshToken)
                .tokenType("Bearer")
                .expiresIn(expiresIn)
                .userName(userName)
                .userType(userType)
                .build();
    }
}
