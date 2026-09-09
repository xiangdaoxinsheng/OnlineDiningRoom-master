FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TOMCAT_VERSION=9.0.107
# Spring 4.2.4 / Shiro 1.4 stack runs on Java 8; the WAR is compiled and served with JDK 8.
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64

# System toolchain: JDK 8 (build + runtime), Maven, MariaDB, and utilities.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        openjdk-8-jdk-headless \
        maven \
        mariadb-server \
        curl \
        ca-certificates \
        git \
        sudo \
        tar \
    && rm -rf /var/lib/apt/lists/*

# Tomcat 9 serves the javax.servlet (Servlet 2.5) WAR. Tomcat 10+ uses jakarta.* and is incompatible.
RUN curl -fsSL -o /tmp/tomcat.tar.gz \
        "https://archive.apache.org/dist/tomcat/tomcat-9/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz" \
    && mkdir -p /opt/tomcat9 \
    && tar xzf /tmp/tomcat.tar.gz -C /opt/tomcat9 --strip-components=1 \
    && rm -f /tmp/tomcat.tar.gz \
    && printf 'export JAVA_HOME=%s\nexport CATALINA_OPTS="-Xms256m -Xmx512m"\n' "$JAVA_HOME" \
        > /opt/tomcat9/bin/setenv.sh \
    && chmod +x /opt/tomcat9/bin/setenv.sh

# The Cloud Agent runs as the "ubuntu" user; give it passwordless sudo and own Tomcat.
RUN echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/90-ubuntu \
    && chmod 0440 /etc/sudoers.d/90-ubuntu \
    && chown -R ubuntu:ubuntu /opt/tomcat9

USER ubuntu
