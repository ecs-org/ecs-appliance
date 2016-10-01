FROM tomcat:8
MAINTAINER felix@erkinger.at

ENV HOSTNAME localhost

# download and check hash of war
RUN curl -f -m 120 --connect-timeout 5 -s -S -o /usr/local/tomcat/webapps/bkuonline.war https://joinup.ec.europa.eu/system/files/project/bkuonline-1.3.23.war
RUN echo "f43f49cbd7ef4df56741097ff5f0637a83cf6cb64701bc484633257ec122dc6a */usr/local/tomcat/webapps/bkuonline.war" | sha256sum -c -

RUN cat <<"EOF" /usr/local/tomcat/webapps/bkuonline/conf/bkuonline.xml \
<?xml version="1.0" encoding="UTF-8"?> \
<Context> \
    <Parameter name="configurationResource" value="file://app/mocca-configuration.xml" override="false"/> \
</Context> \
EOF

RUN cat <<"EOF" | sed -re "s/HOSTNAME/$HOSTNAME/g" > /app/mocca-configuration.xml \
<?xml version="1.0" encoding="UTF-8"?> \
<MoccaConfiguration version="1.0"> \
  <DataURLConnection> \
    <Whitelist>^https://HOSTNAME.*</Whitelist> \
  </DataURLConnection> \
</MoccaConfiguration> \
EOF

CMD ["catalina.sh", "run"]
