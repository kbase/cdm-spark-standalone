FROM bitnami/spark:3.5.1

# Switch to root to install packages
# https://github.com/bitnami/containers/tree/main/bitnami/spark#installing-additional-jars
USER root

# Create a non-root user
# User 1001 is not defined in /etc/passwd in the bitnami/spark image, causing various issues.
# References:
# https://github.com/bitnami/containers/issues/52698
# https://github.com/bitnami/containers/pull/52661
# Uses an existing UID that owns the /opt/bitnami/spark files to avoid a chown
RUN groupadd -r spark && useradd -u 1001 -r -g spark spark_user

RUN apt-get update && apt-get install -y \
    # tools for troubleshooting network issues
    iputils-ping dnsutils netcat-openbsd \
    # Redis client for interacting with Redis server
    redis-tools \
    wget curl \
    tini \
    && rm -rf /var/lib/apt/lists/*

# Install MinIO client
ENV MC_VER=2025-05-21T01-59-54Z
RUN echo "Installing MinIO client..." \
    && wget -q https://dl.min.io/client/mc/release/linux-amd64/archive/mc.RELEASE.${MC_VER} -O /usr/local/bin/mc \
    && chmod +x /usr/local/bin/mc \
    && mc --version \
    && echo "MinIO client installed successfully"

ENV HADOOP_AWS_VER=3.3.4
# NOTE: ensure Delta Spark jar version matches python pip delta-spark version specified in the Pipfile
ENV DELTA_SPARK_VER=3.2.0
ENV SCALA_VER=2.12
ENV POSTGRES_JDBC_VER=42.2.23
ENV SPARK_REDIS_VER=3.1.0
ENV SPARK_XML_VER=0.18.0

# Run Gradle task to download JARs to /gradle/gradle_jars location
COPY build.gradle settings.gradle gradlew /gradle/
COPY gradle /gradle/gradle
ENV GRADLE_JARS_DIR=gradle_jars
RUN /gradle/gradlew -p /gradle build && \
    cp -r /gradle/${GRADLE_JARS_DIR}/* /opt/bitnami/spark/jars/ && \
    rm -rf /gradle

# Install uv and Python dependencies
RUN pip3 install --upgrade pip && \
    pip3 install uv
COPY pyproject.toml uv.lock .python-version ./
ENV UV_PROJECT_ENVIRONMENT=/opt/bitnami/python
RUN uv sync --locked --inexact --no-dev

COPY ./scripts/ /opt/scripts/
RUN chmod a+x /opt/scripts/*.sh

# Copy the configuration files
COPY ./config/ /opt/config/

RUN chown -R spark_user:spark /opt/scripts /opt/config

# Switch back to non-root user
USER spark_user

ENTRYPOINT ["tini", "--", "/opt/scripts/entrypoint.sh"]
