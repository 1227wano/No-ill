# Multi-stage Dockerfile
LABEL version="1.0"
LABEL description="No ill Spring boot backend"


# 1. Builder Stage: Gradle 빌드
FROM eclipse-temurin:21-jdk-alpine AS builder
WORKDIR /app

# 캐싱 효율: 의존성 파일 먼저 복사
COPY gradlew . gradle/ build.gradle settings.gradle ./
RUN chmod +x ./gradlew
COPY src src
RUN ./gradlew clean build -x test --no-daemon

# 2. Runtime Stage: JRE + JAR만
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY --from=builder /app/build/libs/*.jar app.jar

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/actuator/health || exit 1
