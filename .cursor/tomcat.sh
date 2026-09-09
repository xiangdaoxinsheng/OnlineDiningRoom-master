#!/usr/bin/env bash
# Runs Tomcat 9 in the foreground so its logs stay visible in the terminal.
set -euo pipefail

export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
exec /opt/tomcat9/bin/catalina.sh run
