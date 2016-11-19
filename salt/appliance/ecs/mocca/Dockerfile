FROM tomcat:8-jre8
MAINTAINER felix@erkinger.at
# to be used with an frontend ssl webserver, expects input is comming from https
# run script expects a fullchain server ssl cert at /app/import/server.cert.pem

ENV HOSTNAME localhost

RUN mkdir -p /app/mocca /app/import
RUN rm -rf $CATALINA_HOME/webapps/*

RUN curl -f -m 120 --connect-timeout 10 -s -S -o /app/mocca/bkuonline.war https://joinup.ec.europa.eu/system/files/project/bkuonline-1.3.23.war
RUN echo "f43f49cbd7ef4df56741097ff5f0637a83cf6cb64701bc484633257ec122dc6a */app/mocca/bkuonline.war" | sha256sum -c -

RUN printf "%s" '\
<?xml version="1.0" encoding="UTF-8"?>\
<Context>\
    <Paramter name="configurationResource" value="file://app/mocca/bkuonline-configuration.xml" override="false"/>\
</Context>\
' > /usr/local/tomcat/conf/Catalina/localhost/bkuonline.xml

RUN printf "%s" '\
<?xml version="1.0" encoding="UTF-8"?>\
<MoccaConfiguration version="1.0">\
  <DataURLConnection>\
    <Whitelist>^https://HOSTNAME.*</Whitelist>\
  </DataURLConnection>\
</MoccaConfiguration>\
' > /app/mocca/bkuonline-configuration.xml.tmpl

# tell connector that our uplink is a https proxy and reconnects should go to https
RUN sed /usr/local/tomcat/conf/server.xml -r -i \
-e 's/(<Connector port="8080" protocol="HTTP\/1.1").*$/\1 secure="true" scheme="https" proxyPort="443"/'

COPY mocca-catalina.sh /app/mocca/mocca-catalina.sh
RUN chmod +x /app/mocca/mocca-catalina.sh

# extract bkuonline so we can add cert at runtime
RUN mkdir -p /usr/local/tomcat/webapps/bkuonline; unzip /app/mocca/bkuonline.war -d /usr/local/tomcat/webapps/bkuonline

CMD ["/app/mocca/mocca-catalina.sh", "run"]
