# Java & Spring Boot 서버 코드 컨벤션

## 1. 목적

본 문서는 팀 프로젝트에서 Java 및 Spring Boot 기반 서버 개발 시 코드 일관성을 유지하고, 협업 효율과 유지보수성을 향상시키기 위한 최소한의 규칙을 정의한다.

본 컨벤션은 **Google Java Style Guide**와 **Spring 공식 권장 방식**을 기본 기준으로 하며, 불필요한 논쟁을 방지하기 위해 자동화 가능한 규칙 위주로 구성한다.

---

## 2. 네이밍 규칙

### 2.1 클래스

- PascalCase 사용
- 역할이 명확히 드러나야 함

```java
UserService
OrderController
PaymentRepository
```

### 2.2 메서드 / 변수

- camelCase 사용
- 의미 없는 축약 금지 (cnt, usr 등)
- 메서드는 동사형
- 변수는 명사형

```java
findUserById()
orderCount
```

### 2.3 상수

- UPPER_SNAKE_CASE 사용

```java
private static final int MAX_RETRY_COUNT = 3;
```

---

## 3. 패키지 구조

### 3.1 기본 원칙

- 기능(도메인) 단위 패키지 구조를 사용한다.
- 계층(controller, service 등) 기준 분리는 지양한다.

### 3.2 예시

```
com.example.project
 └─ user
     ├─ UserController
     ├─ UserService
     ├─ UserRepository
     └─ User
```

---

## 4. 계층별 역할 규칙

### 4.1 Controller

- `@RestController`만 사용한다.
- 요청/응답 처리만 담당하며 비즈니스 로직을 포함하지 않는다.
- URL은 복수형, kebab-case를 사용한다.

```java
@RequestMapping("/api/users")
```

### 4.2 Service

- 비즈니스 로직을 담당한다.
- 트랜잭션 처리는 Service 계층에서만 수행한다.

```java
@Transactional
public void createUser() { }
```

- Service → Service 호출은 허용한다.
- Repository → Repository 호출은 금지한다.

### 4.3 Repository

- `JpaRepository`를 상속하여 사용한다.
- 메서드 네이밍으로 쿼리 의도를 표현한다.

```java
Optional<User> findByEmail(String email);
```

---

## 5. DTO 규칙

- Entity를 Controller에서 직접 반환하지 않는다.
- Request DTO와 Response DTO를 명확히 분리한다.

```java
UserCreateRequestDto
UserResponseDto
```

- DTO는 불변 객체를 권장한다.

---

## 6. 예외 처리

- `@ControllerAdvice`를 사용하여 전역 예외 처리를 한다.
- 모든 커스텀 예외는 RuntimeException을 상속한다.

```java
throw new UserNotFoundException(userId);
```

---

## 7. 로그 규칙

- `System.out.println` 사용 금지
- `Slf4j` 로깅을 사용한다.

```java
log.info("User created. userId={}", userId);
```

---

---

## 9. 운영 원칙

- 본 컨벤션은 프로젝트 진행 중 필요에 따라 합의 후 확장할 수 있다.
- 명시되지 않은 사항은 Google Java Style Guide를 따른다.