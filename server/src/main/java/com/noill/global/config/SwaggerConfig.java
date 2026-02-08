package com.noill.global.config;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.List;

@Configuration
public class SwaggerConfig {

    @Bean
    public OpenAPI openAPI() {
        // 1. 보안 스키마 정의 (Header에 Authorization: Bearer {JWT} 추가용)
        SecurityScheme securityScheme = new SecurityScheme()
                .name("jwtToken")             // 컨트롤러의 @SecurityRequirement(name = "jwtToken")과 일치해야 함
                .type(SecurityScheme.Type.HTTP)
                .scheme("bearer")
                .bearerFormat("JWT")
                .description("App 토큰 또는 Display 토큰을 입력하세요.");

        // 2. 보안 요구사항 설정
        SecurityRequirement securityRequirement = new SecurityRequirement().addList("jwtToken");

        return new OpenAPI()
                .components(new Components().addSecuritySchemes("jwtToken", securityScheme))
                .info(new Info()
                        .title("노일이 프로젝트 API 명세서")
                        .description("협업을 위한 API 문서 (App/Display 토큰 혼용)")
                        .version("v1.0.0"));
    }
}
