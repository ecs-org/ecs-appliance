FROM tomcat:8
MAINTAINER felix@erkinger.at

ENV HOSTNAME localhost
ENV CATALINA_OPTS "-Dpdf-as-web.conf=/app/pdf-as-web/pdf-as-web.properties"

RUN mkdir -p /app/pdf-as-web

# download and check hash of files
RUN curl -f -m 120 --connect-timeout 10 -s -S -o /usr/local/tomcat/webapps/pdf-as-web.war https://joinup.ec.europa.eu/site/pdf-as/releases/4.0.11/pdf-as-web-4.0.11.war
RUN echo "2008e413032fc926e30b2d666f4363707328a5171a4b170c0fb0599a4e894421 */usr/local/tomcat/webapps/pdf-as-web.war" | sha256sum -c -

RUN curl -f -m 120 --connect-timeout 10 -s -S -o /app/pdf-as-web/defaultConfig.zip https://joinup.ec.europa.eu/site/pdf-as/releases/4.0.11/cfg/defaultConfig.zip
RUN echo "d6a413702b4a73d056c2d8e61d815ed99b2743996998bebed86e4c4c5b64e665 */app/pdf-as-web/defaultConfig.zip" | sha256sum -c -
RUN unzip /app/pdf-as-web/defaultConfig.zip -d /app/pdf-as-web

COPY pdf-as-web.properties /app/pdf-as-web/pdf-as-web.properties.tmpl

CMD ["/bin/sh", "-c", "sed \"s/HOSTNAME/$HOSTNAME/g\" /app/pdf-as-web/pdf-as-web.properties.tmpl > /app/pdf-as-web/pdf-as-web.properties; exec /usr/local/tomcat/bin/catalina.sh run"]
