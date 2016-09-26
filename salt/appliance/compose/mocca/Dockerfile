FROM tomcat:8
MAINTAINER felix@erkinger.at

# download and check hash of war
RUN curl -f -m 120 --connect-timeout 5 -s -S -o /usr/local/tomcat/webapps/bkuonline.war https://joinup.ec.europa.eu/system/files/project/bkuonline-1.3.23.war
RUN echo "f43f49cbd7ef4df56741097ff5f0637a83cf6cb64701bc484633257ec122dc6a */usr/local/tomcat/webapps/bkuonline.war" | sha256sum -c -

COPY bkuonline.xml /usr/local/
COPY mocca-configuration.xml /usr/local/

CMD ["catalina.sh", "run"]
