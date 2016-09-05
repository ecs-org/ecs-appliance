FROM tomcat:8
MAINTAINER felix@erkinger.at

ENV CATALINA_OPTS "-Dpdf-as-web.conf=/app/pdf-as-web.properties"
* https://joinup.ec.europa.eu/site/pdf-as/releases/4.0.11/pdf-as-web-4.0.11.war
* sha256=2008e413032fc926e30b2d666f4363707328a5171a4b170c0fb0599a4e894421  pdf-as-web-4.0.11.war

ADD "your.war" /usr/local/tomcat/webapps/pdf-as-web.war
ADD pdf-as-web.properties /app/pdf-as-web.properties

CMD ["catalina.sh", "run"]
