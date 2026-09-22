ARG JAVA_VERSION=25

# Build and test inside the container; no host JDK is required.
FROM docker.io/library/eclipse-temurin:${JAVA_VERSION}-jdk AS build
WORKDIR /workspace
COPY gradlew build.gradle.kts settings.gradle.kts ./
COPY gradle ./gradle
RUN chmod +x gradlew
COPY src ./src
RUN ./gradlew --no-daemon test bootJar

# The application JAR includes H2 and generated OpenAPI/Swagger UI support.
# H2 runs in memory inside Java; no database service or volume is needed.
FROM docker.io/library/eclipse-temurin:${JAVA_VERSION}-jre AS runtime
WORKDIR /app
COPY --from=build /workspace/build/libs/app.jar ./app.jar
USER 10001:10001
ENV JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=50.0 -XX:+ExitOnOutOfMemoryError"
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
