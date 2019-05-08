FROM tomcat:8.5.15-jre8
MAINTAINER felix@erkinger.at
# to be used with an frontend ssl webserver, expects input is comming from https
# run script expects a fullchain server ssl cert at /import/server.cert.pem

ENV HOSTNAME localhost
ENV CATALINA_OPTS "-Xms350m -Xmx1024m -Dpdf-as-web.conf=/app/pdf-as-web/pdf-as-web.properties"

RUN mkdir -p /app/pdf-as-web /app/import
RUN rm -rf $CATALINA_HOME/webapps/*

RUN curl -f -m 120 --insecure --connect-timeout 10 -s -S -o /usr/local/tomcat/webapps/pdf-as-web.war https://ecs-org.github.io/ecs-docs/pdf-as-web-4.1.0.war
RUN echo "d625cd40a0baadf9ccf2a9bb46f6808efb7929e3fbe107b087b8c42f5b6c1971 */usr/local/tomcat/webapps/pdf-as-web.war" | sha256sum -c -
RUN curl -f -m 120 --insecure --connect-timeout 10 -s -S -o /app/defaultConfig.zip https://ecs-org.github.io/ecs-docs/defaultConfig-4.1.1.zip
RUN echo "392718b4b8e57582ec529061c25437b3858574a90214e429069cbc084333ca8d */app/defaultConfig.zip" | sha256sum -c -
RUN unzip /app/defaultConfig.zip -d /app/pdf-as-web

# tell connector that our uplink is a https proxy and reconnects should go to https
RUN sed /usr/local/tomcat/conf/server.xml -r -i \
-e 's/(<Connector port="8080" protocol="HTTP\/1.1").*$/\1 secure="true" scheme="https" proxyPort="443"/'

COPY pdf-as-web.properties /app/pdf-as-web/pdf-as-web.properties.tmpl
COPY pdfas-catalina.sh /app/pdf-as-web/pdfas-catalina.sh
RUN  chmod +x /app/pdf-as-web/pdfas-catalina.sh

CMD ["/app/pdf-as-web/pdfas-catalina.sh", "run"]
