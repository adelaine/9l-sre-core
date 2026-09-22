# Build and test inside the container; no host JDK is required.
FROM docker.io/library/eclipse-temurin:25-jdk AS build
WORKDIR /workspace
COPY gradlew build.gradle.kts settings.gradle.kts ./
COPY gradle ./gradle
RUN chmod +x gradlew
COPY src ./src
RUN ./gradlew --no-daemon test bootJar

# Only the runtime and application are included in the final image.
FROM docker.io/library/eclipse-temurin:25-jre
WORKDIR /app
COPY --from=build /workspace/build/libs/app.jar ./app.jar
USER 10001:10001
ENV JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=50.0 -XX:+ExitOnOutOfMemoryError"
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
