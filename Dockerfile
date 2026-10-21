# ============ ETAPA 1: BUILDER ============
FROM maven:3.9.6-eclipse-temurin-17-alpine AS builder
ARG STUDENT_ID
WORKDIR /build

# Solo el pom.xml primero: la descarga de dependencias queda en caché
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Ahora el código fuente (cambia seguido, no invalida el caché anterior)
COPY src ./src
RUN mvn package -DskipTests -B

# ============ ETAPA 2: RUNTIME ============
FROM eclipse-temurin:17-jre-alpine
ARG STUDENT_ID

RUN addgroup -S -g 10001 sensorgroup && \
    adduser -S -u 10001 -G sensorgroup sensor_user

WORKDIR /app
COPY --from=builder /build/target/app.jar /app/app.jar
RUN chown -R sensor_user:sensorgroup /app

ENV OPERATOR_ID=${STUDENT_ID}
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -XX:+ExitOnOutOfMemoryError"

EXPOSE 8080
USER sensor_user

ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar /app/app.jar"]
