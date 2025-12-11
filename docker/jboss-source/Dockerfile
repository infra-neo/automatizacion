# Based on Red Hat Universal Base Image
FROM registry.access.redhat.com/ubi7/ubi:7.9

LABEL maintainer="Migration Team"
LABEL description="JBoss EAP 6.4 with Java 1.7 - Source Environment"

# Install Java 1.7 and required packages
RUN yum install -y \
    java-1.7.0-openjdk \
    java-1.7.0-openjdk-devel \
    unzip \
    wget \
    curl \
    net-tools \
    && yum clean all

ENV JAVA_HOME=/usr/lib/jvm/java-1.7.0-openjdk
ENV PATH=$JAVA_HOME/bin:$PATH

# Create JBoss user
RUN groupadd -r jboss -g 1000 && \
    useradd -u 1000 -r -g jboss -m -d /opt/jboss -s /sbin/nologin -c "JBoss user" jboss

# Set working directory
WORKDIR /opt/jboss

# Download and install JBoss EAP 6.4 (using wildfly 10 as alternative for demo purposes)
# In real scenario, you would use actual JBoss EAP binaries
ENV JBOSS_VERSION=10.1.0.Final
ENV JBOSS_HOME=/opt/jboss/wildfly-${JBOSS_VERSION}

RUN curl -O https://download.jboss.org/wildfly/10.1.0.Final/wildfly-${JBOSS_VERSION}.tar.gz && \
    tar xf wildfly-${JBOSS_VERSION}.tar.gz && \
    rm wildfly-${JBOSS_VERSION}.tar.gz && \
    chown -R jboss:jboss ${JBOSS_HOME}

# Add PostgreSQL JDBC driver
RUN mkdir -p ${JBOSS_HOME}/modules/system/layers/base/org/postgresql/main && \
    curl -o ${JBOSS_HOME}/modules/system/layers/base/org/postgresql/main/postgresql-42.2.24.jar \
    https://jdbc.postgresql.org/download/postgresql-42.2.24.jar

# Copy module configuration
COPY module.xml ${JBOSS_HOME}/modules/system/layers/base/org/postgresql/main/

# Copy standalone configuration
COPY standalone.xml ${JBOSS_HOME}/standalone/configuration/

# Copy startup script
COPY start-jboss.sh /opt/jboss/
RUN chmod +x /opt/jboss/start-jboss.sh

# Expose ports
EXPOSE 8080 9990

USER jboss

# Start JBoss
CMD ["/opt/jboss/start-jboss.sh"]
