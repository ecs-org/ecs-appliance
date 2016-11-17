FROM tomcat:8
MAINTAINER felix@erkinger.at

ENV HOSTNAME localhost
ENV CATALINA_OPTS "-Dpdf-as-web.conf=/app/pdf-as-web/pdf-as-web.properties"

RUN mkdir -p /app/pdf-as-web /app/import

RUN curl -f -m 120 --connect-timeout 10 -s -S -o /usr/local/tomcat/webapps/pdf-as-web.war https://joinup.ec.europa.eu/site/pdf-as/releases/4.0.11/pdf-as-web-4.0.11.war
RUN echo "2008e413032fc926e30b2d666f4363707328a5171a4b170c0fb0599a4e894421 */usr/local/tomcat/webapps/pdf-as-web.war" | sha256sum -c -

RUN curl -f -m 120 --connect-timeout 10 -s -S -o /app/defaultConfig.zip https://joinup.ec.europa.eu/site/pdf-as/releases/4.0.11/cfg/defaultConfig.zip
RUN echo "d6a413702b4a73d056c2d8e61d815ed99b2743996998bebed86e4c4c5b64e665 */app/defaultConfig.zip" | sha256sum -c -
RUN unzip /app/defaultConfig.zip -d /app/pdf-as-web; rm /app/defaultConfig.zip

COPY pdf-as-web.properties /app/pdf-as-web/pdf-as-web.properties.tmpl
COPY pdfas-catalina.sh /app/pdf-as-web/pdfas-catalina.sh
RUN  chmod +x /app/pdf-as-web/pdfas-catalina.sh

# run script expects a fullchain server ssl cert at /import/server.cert.pem
CMD ["/app/pdf-as-web/pdfas-catalina.sh", "run"]
