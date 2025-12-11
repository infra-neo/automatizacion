# Based on Red Hat Universal Base Image
FROM registry.access.redhat.com/ubi9/ubi:9.3

LABEL maintainer="Migration Team"
LABEL description="WildFly 31 with Java 21 - Target Environment"

# Install Java 21 and required packages
RUN dnf install -y \
    java-21-openjdk \
    java-21-openjdk-devel \
    unzip \
    wget \
    curl \
    net-tools \
    && dnf clean all

ENV JAVA_HOME=/usr/lib/jvm/java-21-openjdk
ENV PATH=$JAVA_HOME/bin:$PATH

# Verify Java version
RUN java -version

# Create JBoss user
RUN groupadd -r jboss -g 1000 && \
    useradd -u 1000 -r -g jboss -m -d /opt/jboss -s /sbin/nologin -c "JBoss user" jboss

# Set working directory
WORKDIR /opt/jboss

# Download and install WildFly 31
ENV WILDFLY_VERSION=31.0.1.Final
ENV WILDFLY_HOME=/opt/jboss/wildfly
ENV JBOSS_HOME=/opt/jboss/wildfly

RUN curl -O https://github.com/wildfly/wildfly/releases/download/${WILDFLY_VERSION}/wildfly-${WILDFLY_VERSION}.tar.gz && \
    tar xf wildfly-${WILDFLY_VERSION}.tar.gz && \
    mv wildfly-${WILDFLY_VERSION} wildfly && \
    rm wildfly-${WILDFLY_VERSION}.tar.gz && \
    chown -R jboss:jboss ${WILDFLY_HOME}

# Add PostgreSQL JDBC driver
RUN mkdir -p ${WILDFLY_HOME}/modules/system/layers/base/org/postgresql/main && \
    curl -o ${WILDFLY_HOME}/modules/system/layers/base/org/postgresql/main/postgresql-42.7.1.jar \
    https://jdbc.postgresql.org/download/postgresql-42.7.1.jar

# Copy module configuration
COPY module.xml ${WILDFLY_HOME}/modules/system/layers/base/org/postgresql/main/

# Copy standalone configuration
COPY standalone.xml ${WILDFLY_HOME}/standalone/configuration/

# Copy startup script
COPY start-wildfly.sh /opt/jboss/
RUN chmod +x /opt/jboss/start-wildfly.sh

# Expose ports
EXPOSE 8080 9990

USER jboss

# Start WildFly
CMD ["/opt/jboss/start-wildfly.sh"]
