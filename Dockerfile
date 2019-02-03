# Use latest jboss/base-jdk:8 image as the base
FROM jboss/base-jdk:8

# Set the WILDFLY_VERSION env variable
ENV WILDFLY_VERSION 10.1.0.Final
ENV WILDFLY_SHA1 9ee3c0255e2e6007d502223916cefad2a1a5e333
ENV JBOSS_HOME /opt/jboss/wildfly

USER root

# Add the WildFly distribution to /opt, and make wildfly the owner of the extracted tar content
# Make sure the distribution is available from a well-known place
RUN cd $HOME \
    && curl -O https://download.jboss.org/wildfly/$WILDFLY_VERSION/wildfly-$WILDFLY_VERSION.tar.gz \
    && sha1sum wildfly-$WILDFLY_VERSION.tar.gz | grep $WILDFLY_SHA1 \
    && tar xf wildfly-$WILDFLY_VERSION.tar.gz \
    && mv $HOME/wildfly-$WILDFLY_VERSION $JBOSS_HOME \
    && rm wildfly-$WILDFLY_VERSION.tar.gz \
    && chown -R jboss:0 ${JBOSS_HOME} \
    && chmod -R g+rw ${JBOSS_HOME}

# Ensure signals are forwarded to the JVM process correctly for graceful shutdown
ENV LAUNCH_JBOSS_IN_BACKGROUND true

ENV CONNECTOR_VERSION mysql-connector-java-8.0.13

RUN mkdir -p /opt/jboss/wildfly/modules/com/mysql/main

RUN curl -O -L https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-8.0.13.zip \
  && unzip $CONNECTOR_VERSION.zip \
  && mv $CONNECTOR_VERSION/$CONNECTOR_VERSION-bin.jar /opt/jboss/wildfly/modules/com/mysql/main/$CONNECTOR_VERSION.jar \
  && rm -r $CONNECTOR_VERSION && rm $CONNECTOR_VERSION.zip
COPY module.xml /opt/jboss/wildfly/modules/com/mysql/main/module.xml

USER jboss


# Expose the ports we're interested in
EXPOSE 8080

# Set the default command to run on boot
# This will boot WildFly in the standalone mode and bind to all interface

RUN /opt/jboss/wildfly/bin/add-user.sh admin Admin#007 --silent

# CMD ["/opt/jboss/wildfly/bin/standalone.sh", "-b", "0.0.0.0"]
CMD ["/opt/wildfly/bin/standalone.sh", "-c", "standalone-full.xml", "-b", "0.0.0.0", "-bmanagement", "0.0.0.0"]
