FROM tomcat:8
MAINTAINER felix@erkinger.at

ENV HOSTNAME localhost
ENV CATALINA_OPTS "-Dpdf-as-web.conf=/app/pdf-as-web.properties"

# download and check hash of war
RUN curl -f -m 120 --connect-timeout 5 -s -S -o /usr/local/tomcat/webapps/pdf-as-web.war https://joinup.ec.europa.eu/site/pdf-as/releases/4.0.11/pdf-as-web-4.0.11.war
RUN echo "2008e413032fc926e30b2d666f4363707328a5171a4b170c0fb0599a4e894421 */usr/local/tomcat/webapps/pdf-as-web.war" | sha256sum -c -

COPY pdf-as-web.properties /tmp/pdf-as-web.properties
RUN mkdir -p /app; cat /tmp/pdf-as-web.properties | sed -re "s/HOSTNAME/$HOSTNAME/g" > /app/pdf-as-web.properties

CMD ["catalina.sh", "run"]
