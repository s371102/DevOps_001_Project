# Stage 1: Build stage
FROM maven:3.8.1-openjdk-11 AS builder
WORKDIR /build
COPY . .
RUN mvn clean package

# Stage 2: Runtime stage
FROM adoptopenjdk/openjdk11:latest
WORKDIR /usr/src/app
COPY --from=builder /build/target/*.jar app.jar
ENTRYPOINT ["java", "-jar", "app.jar"]
