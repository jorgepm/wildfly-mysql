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
ENV MYSQL_CONNECTOR_VERSION 5.1.16
RUN wget "http://central.maven.org/maven2/mysql/mysql-connector-java/${MYSQL_CONNECTOR_VERSION}/mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.jar" -O /opt/jboss/mysql-connector-java-${MYSQL_CONNECTOR_VERSION}-bin.jar
# this is to fix "Deploying non-JDBC-compliant driver class"
RUN mkdir -p META-INF/services
RUN echo "com.mysql.jdbc.Driver" > META-INF/services/java.sql.Driver
RUN jar uf /opt/jboss/mysql-connector-java-${MYSQL_CONNECTOR_VERSION}-bin.jar META-INF

ADD datasource.cli /opt/jboss/datasource.cli
RUN sed -i -e s/MYSQL-CONNECTOR-VERSION/${MYSQL_CONNECTOR_VERSION}/g /opt/jboss/datasource.cli

RUN /opt/jboss/wildfly/bin/jboss-cli.sh --file=/opt/jboss/datasource.cli

# Fix for WFLYCTL0056: Could not rename /opt/jboss/wildfly/standalone/configuration/standalone_xml_history/current to ...
RUN rm -rf /opt/jboss/wildfly-$WILDFLY_VERSION.Final/standalone/configuration/standalone_xml_history


USER jboss


# Expose the ports we're interested in
EXPOSE 8080

# Set the default command to run on boot
# This will boot WildFly in the standalone mode and bind to all interface

RUN /opt/jboss/wildfly/bin/add-user.sh admin Admin#007 --silent

# CMD ["/opt/jboss/wildfly/bin/standalone.sh", "-b", "0.0.0.0"]
CMD ["/opt/wildfly/bin/standalone.sh", "-c", "standalone-full.xml", "-b", "0.0.0.0", "-bmanagement", "0.0.0.0"]
