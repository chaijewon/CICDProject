# Java 21 실행 환경을 사용한다
FROM eclipse-temurin:21-jre

# 컨테이너 내부의 작업 디렉터리
WORKDIR /app

# Spring Boot가 만든 JAR 파일을 컨테이너로 복사
COPY build/libs/*.jar app.jar

# 컨테이너가 사용하는 애플리케이션 포트
EXPOSE 8080

# 컨테이너가 시작되면 Spring Boot 실행
ENTRYPOINT ["java", "-jar", "app.jar"]