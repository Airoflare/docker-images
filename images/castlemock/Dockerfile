# Castle Mock (REST & SOAP service mocking), built from source from the last
# open-source release.
#
# Castle Mock is archived, and its Docker Hub images are scheduled for deletion.
# This image compiles v1.68 from a preserved fork
# (github.com/Airoflare/castlemock-preserve) into its executable Spring Boot jar
# and runs it on a maintained Eclipse Temurin JRE. The Castle Mock version is
# frozen; rebuilds only refresh the JDK/JRE for runtime security fixes.
ARG CASTLEMOCK_VERSION

# Build stage - compile the embedded-Tomcat executable jar (deploy-tomcat-jar).
FROM maven:3.9-eclipse-temurin-21 AS builder

# Commit of the last open-source release (v1.68). Keep it in step with
# CASTLEMOCK_VERSION in scripts/helpers/castlemock.sh when moving to another.
ARG CASTLEMOCK_COMMIT=130251adcd8ba3413395469006808d93dcb2f826
ARG CASTLEMOCK_REPO=https://github.com/Airoflare/castlemock-preserve.git

WORKDIR /src
RUN git init -q && git remote add origin "$CASTLEMOCK_REPO" && \
    git fetch -q --depth 1 origin "$CASTLEMOCK_COMMIT" && git checkout -q FETCH_HEAD

# -DskipTests (not maven.test.skip) so test-jar classifiers still build. The .m2
# cache mount speeds up repeated builds without landing in a layer.
RUN --mount=type=cache,target=/root/.m2 \
    mvn -q -pl :deploy-tomcat-jar -am -DskipTests package && \
    cp deploy/deploy-tomcat/deploy-tomcat-jar/target/castlemock.jar /castlemock.jar

# Runtime stage - a maintained JRE (refreshed by Renovate + weekly rebuilds).
FROM eclipse-temurin:21-jre-alpine AS final

ARG CASTLEMOCK_VERSION

LABEL org.opencontainers.image.title="castlemock" \
      org.opencontainers.image.description="Castle Mock (REST & SOAP service mocking), last open-source release, on a maintained JRE" \
      org.opencontainers.image.version="${CASTLEMOCK_VERSION}" \
      org.opencontainers.image.source="https://github.com/Airoflare/docker-images" \
      org.opencontainers.image.url="https://github.com/castlemock/castlemock" \
      org.opencontainers.image.licenses="Apache-2.0"

# Castle Mock stores its data under ${user.home}/.castlemock; give UID 55555 a
# writable home and data dir. No VOLUME - a declared volume mountpoint would be
# created root-owned and break writes; mount one yourself for persistence.
RUN mkdir -p /castlemock/.castlemock && chown -R 55555:55555 /castlemock
COPY --from=builder /castlemock.jar /app/castlemock.jar

ENV HOME=/castlemock
EXPOSE 8080
WORKDIR /castlemock
USER 55555:55555
ENTRYPOINT ["java", "-Duser.home=/castlemock", "-jar", "/app/castlemock.jar"]
