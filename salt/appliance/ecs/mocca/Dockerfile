FROM tomcat:8
MAINTAINER felix@erkinger.at

ENV HOSTNAME localhost

RUN mkdir -p /app/mocca /data

RUN curl -f -m 120 --connect-timeout 10 -s -S -o /app/mocca/bkuonline.war https://joinup.ec.europa.eu/system/files/project/bkuonline-1.3.23.war
RUN echo "f43f49cbd7ef4df56741097ff5f0637a83cf6cb64701bc484633257ec122dc6a */app/mocca/bkuonline.war" | sha256sum -c -

RUN printf "%s" '\
<?xml version="1.0" encoding="UTF-8"?>\
<Context>\
    <Paramter name="configurationResource" value="file://app/mocca/bkuonline-configuration.xml" override="false"/>\
</Context>\
' > /usr/local/tomcat/conf/bkuonline.xml

RUN printf "%s" '\
<?xml version="1.0" encoding="UTF-8"?>\
<MoccaConfiguration version="1.0">\
  <DataURLConnection>\
    <Whitelist>^https://HOSTNAME.*</Whitelist>\
  </DataURLConnection>\
</MoccaConfiguration>\
' > /app/mocca/bkuonline-configuration.xml.tmpl

COPY mocca-catalina.sh /app/mocca/mocca-catalina.sh
RUN chmod +x /app/mocca/mocca-catalina.sh

# extract bkuonline so we can add cert at runtime
RUN mkdir -p /usr/local/tomcat/webapps/bkuonline; unzip /app/mocca/bkuonline.war -d /usr/local/tomcat/webapps/bkuonline

# run script expects a fullchain server ssl cert at /data/server.cert.pem
CMD ["/app/mocca/mocca-catalina.sh", "run"]
