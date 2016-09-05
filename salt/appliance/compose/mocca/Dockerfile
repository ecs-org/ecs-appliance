FROM tomcat:8
MAINTAINER felix@erkinger.at

tomcat:8 container has both curl,wget,sha256sum
use curl because it respects http_proxy

* https://joinup.ec.europa.eu/system/files/project/bkuonline-1.3.23.war
* sha256=f43f49cbd7ef4df56741097ff5f0637a83cf6cb64701bc484633257ec122dc6a  bkuonline-1.3.23.war

ADD "your.war" /usr/local/tomcat/webapps/bkuonline.war
ADD bkuonline.xml /usr/local/
ADD mocca-configuration.xml /usr/local/

CMD ["catalina.sh", "run"]
